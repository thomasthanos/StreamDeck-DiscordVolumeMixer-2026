#include "dvmplugin.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QSettings>
#include <QDateTime>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QUrl>
#include "dvmdevice.h"

#include "action/action_openmixer.h"
#include "action/action_vcminfo.h"
#include "action/action_vcmvolume.h"
#include "action/action_vcmpaging.h"
#include "action/action_back.h"
#include "action/action_deafen.h"
#include "action/action_microphone.h"

#include <cmath>

DVMPlugin::DVMPlugin() {
	registerActionType<Action_OpenMixer>("com.thomast.discordmixer.openmixer");
	registerActionType<Action_VCMInfo>("com.thomast.discordmixer.user");
	registerActionType<Action_VCMVolume>("com.thomast.discordmixer.volumeup");
	registerActionType<Action_VCMVolume>("com.thomast.discordmixer.volumedown");
	registerActionType<Action_VCMPaging>("com.thomast.discordmixer.nextpage");
	registerActionType<Action_VCMPaging>("com.thomast.discordmixer.previouspage");
	registerActionType<Action_Back>("com.thomast.discordmixer.back");
	registerActionType<Action_Microphone>("com.thomast.discordmixer.microphone");
	registerActionType<Action_Deafen>("com.thomast.discordmixer.deafen");

	connect(this, &QStreamDeckPlugin::initialized, this, &DVMPlugin::onInitialized);
	connect(this, &QStreamDeckPlugin::eventReceived, this, &DVMPlugin::onStreamDeckEventReceived);

	connect(&discord, &QDiscord::messageReceived, this, &DVMPlugin::onDiscordMessageReceived);
	connect(&discord, &QDiscord::connected, this, [this] {
		discordReconnectFailures_ = 0;
		discordReconnectTimer_.stop();
	});
	connect(&discord, &QDiscord::disconnected, this, [this] {
		isDiscordConnecting = false;
		currentVoiceChannelID.clear();
		voiceChannelMembers.clear();
		speakingVoiceChannelMembers.clear();
		voiceChannelMemberIxOffset = 0;

		scheduleDiscordReconnect();

		emit buttonsUpdateRequested();
	});

	discordConnectTimeoutTimer_.setSingleShot(true);
	discordConnectTimeoutTimer_.setInterval(2000);

	discordReconnectTimer_.setInterval(2500);
	discordReconnectTimer_.setSingleShot(true);
	discordReconnectTimer_.callOnTimeout(this, &DVMPlugin::connectToDiscord);

	connect(this, &DVMPlugin::globalSettingsChanged, this, [this] {
		QTimer::singleShot(0, this, [this] {
			const QString clientID = globalSetting("client_id").toString().trimmed();
			const QString clientSecret = globalSetting("client_secret").toString().trimmed();
			if(discord.isConnected() && (clientID != connectedClientID_ || clientSecret != connectedClientSecret_)) {
				// Credentials changed — purge stale OAuth token cache from file and registry
				const QString appDir = QCoreApplication::applicationDirPath();
				const QString oauthPath = !appDir.isEmpty() ? QDir::cleanPath(QDir(appDir).filePath("../discordOauth.json")) : "discordOauth.json";
				QFile::remove(oauthPath);
				QSettings regSettings(QSettings::UserScope, "Elgato Stream Deck Plugin", "com.thomast.discordmixer");
				regSettings.remove("discordOauth");
				qDebug() << "Credentials changed, purged OAuth token cache";
				discord.disconnect();
			}
			if(!discord.isConnected()) {
				discordReconnectTimer_.stop();
				connectToDiscord();
			}
		});
	});
}

DVMPlugin::~DVMPlugin() {

}

void DVMPlugin::connectToDiscord() {
	if(discord.isConnected() || discord.isProcessing())
		return;

	const QString clientID = globalSetting("client_id").toString().trimmed();
	const QString clientSecret = globalSetting("client_secret").toString().trimmed();
	if(!rejectedClientID_.isEmpty() && clientID == rejectedClientID_)
		return;

	isDiscordConnecting = true;
	emit buttonsUpdateRequested();
	const bool connected = discord.connect(clientID, clientSecret, QStringLiteral("http://localhost:1337/callback"));
	isDiscordConnecting = false;

	if(connected) {
		rejectedClientID_.clear();
		connectedClientID_ = clientID;
		connectedClientSecret_ = clientSecret;
		// Subscribe to voice channel select event
		discord.sendCommand(+QDiscord::CommandType::subscribe, {}, QJsonObject{
			{"evt", "VOICE_CHANNEL_SELECT"},
		});

		{
			auto r = discord.sendCommand(+QDiscord::CommandType::getVoiceSettings);
			connect(r, &QDiscordReply::success, this, [this](const QDiscordMessage &msg) {
				isMicrophoneMuted = msg.data["mute"].toBool();
				isDeafened = msg.data["deaf"].toBool();
				emit buttonsUpdateRequested();
			});
		}

		updateChannelMembersData();
		discordReconnectTimer_.stop();
		emit buttonsUpdateRequested();
	}
	else {
		emit buttonsUpdateRequested();
		const QString err = discord.connectionError();
		if(err == QStringLiteral("BAD CLIENT") || err.contains(QStringLiteral("cancelled"), Qt::CaseInsensitive) || err.contains(QStringLiteral("invalid_scope"), Qt::CaseInsensitive)) {
			rejectedClientID_ = clientID;
			discordReconnectTimer_.stop();
			return;
		}
		if(err == QStringLiteral("NO ID/SECRET")) {
			discordReconnectTimer_.stop();
			return;
		}
		scheduleDiscordReconnect();
	}
}

void DVMPlugin::scheduleDiscordReconnect() {
	const int exponent = qMin(discordReconnectFailures_++, 4);
	const int delayMs = qMin(15000, 1500 * (1 << exponent));
	discordReconnectTimer_.start(delayMs);
}

void DVMPlugin::updateChannelMembersData() {
	if(!discord.isConnected())
		return;

	QDiscordReply *r = discord.sendCommand(+QDiscord::CommandType::getSelectedVoiceChannel);
	connect(r, &QDiscordReply::success, this, [this](const QDiscordMessage &msg) {
		updateCurrentVoiceChannel(msg.data["id"].toString());

		// Update voice channel member list
		{
			const auto arr = msg.data["voice_states"].toArray();

			voiceChannelMembers.clear();

			for(const auto &v: arr) {
				const VoiceChannelMember vs = VoiceChannelMember::fromJson(v.toObject());
				if(vs.userID != discord.userID())
					voiceChannelMembers.insert(vs.userID, vs);
			}
		}

		if(voiceChannelMemberIxOffset >= voiceChannelMembers.size())
			voiceChannelMemberIxOffset = 0;

		emit buttonsUpdateRequested();
	});
}

void DVMPlugin::updateSelfVoiceState(const QDiscordMessage &msg) {
	const QJsonObject json = msg.data;

	if(auto v = json["voice_state"]["self_mute"]; !v.isNull())
		isMicrophoneMuted = v.toBool();

	if(auto v = json["voice_state"]["self_deaf"]; !v.isNull())
		isDeafened = v.toBool();
}

void DVMPlugin::adjustVoiceChannelMemberVolume(VoiceChannelMember &vcm, float stepSize, int numSteps) {
	if(!std::isfinite(stepSize) || stepSize <= 0 || numSteps == 0 || !discord.isConnected())
		return;

	float newVolume = vcm.volume + stepSize * numSteps;
	newVolume = qRound(newVolume / stepSize) * stepSize;
	newVolume = qBound(QDiscord::minVoiceVolume, newVolume, QDiscord::maxVoiceVolume);

	if(newVolume != vcm.volume || vcm.isMuted) {
		vcm.volume = newVolume;
		vcm.isMuted = false;

		discord.sendCommand(+QDiscord::CommandType::setUserVoiceSettings, QJsonObject{
			{"user_id", vcm.userID},
			{"volume",  QDiscord::uiToIPCVolume(newVolume)},
			{"mute",    false},
		});
		emit buttonsUpdateRequested();
	}
}

QPixmap DVMPlugin::getUserAvatar(const QString &userId, const QString &avatarHash) {
	if(userId.isEmpty() || avatarHash.isEmpty())
		return {};

	const QString cacheKey = userId + '_' + avatarHash;
	const auto cachedAvatar = avatarCache_.constFind(cacheKey);
	if(cachedAvatar != avatarCache_.cend())
		return cachedAvatar.value();

	if(avatarDownloadsInFlight_.contains(cacheKey)
			|| avatarRetryAfter_.value(cacheKey) > QDateTime::currentMSecsSinceEpoch())
		return {};

	avatarDownloadsInFlight_.insert(cacheKey);
	const QUrl avatarUrl(QStringLiteral("https://cdn.discordapp.com/avatars/%1/%2.png?size=128")
						 .arg(userId, avatarHash));
	QNetworkReply *reply = avatarNetworkManager_.get(QNetworkRequest(avatarUrl));
	connect(reply, &QNetworkReply::finished, this, [this, reply, cacheKey] {
		avatarDownloadsInFlight_.remove(cacheKey);
		const QByteArray avatarData = reply->readAll();
		const bool networkOk = reply->error() == QNetworkReply::NoError;
		reply->deleteLater();

		const QPixmap avatar = networkOk ? QPixmap::fromImage(QImage::fromData(avatarData)) : QPixmap{};
		if(avatar.isNull()) {
			qWarning() << "Failed to load Discord avatar" << cacheKey;
			avatarRetryAfter_[cacheKey] = QDateTime::currentMSecsSinceEpoch() + 60000;
			return;
		}

		avatarRetryAfter_.remove(cacheKey);
		avatarCache_.insert(cacheKey, avatar);
		emit buttonsUpdateRequested();
	});

	return {};
}

void DVMPlugin::updateCurrentVoiceChannel(const QString &newVoiceChannel) {
	// If the channel changed, update event subscribtions
	if(newVoiceChannel == currentVoiceChannelID)
		return;

	speakingVoiceChannelMembers.clear();

	static const QStringList events{
		"VOICE_STATE_UPDATE", "VOICE_STATE_CREATE", "VOICE_STATE_DELETE", "SPEAKING_START", "SPEAKING_STOP"
	};
	const auto evf = [&](const QString &cmd) {
		const QJsonObject args{{"channel_id", currentVoiceChannelID}};
		for(const QString &e: events)
			discord.sendCommand(cmd, args, {{"evt", e}});
	};

	if(!currentVoiceChannelID.isEmpty())
		evf(+QDiscord::CommandType::unsubscribe);

	currentVoiceChannelID = newVoiceChannel;

	if(!currentVoiceChannelID.isEmpty())
		evf(+QDiscord::CommandType::subscribe);
}

void DVMPlugin::onDiscordMessageReceived(const QDiscordMessage &msg) {
	using ET = QDiscordMessage::EventType;

	switch(msg.event) {

		// Voice channel changed
		case ET::voiceChannelSelect:
			updateCurrentVoiceChannel(msg.data["channel_id"].toString());
			updateChannelMembersData();
			break;

		case ET::voiceStateCreate: {
			const auto m = VoiceChannelMember::fromJson(msg.data);
			if(m.userID == discord.userID())
				updateSelfVoiceState(msg);

			else
				voiceChannelMembers.insert(m.userID, m);

			break;
		}

		case ET::voiceStateUpdate: {
			const auto m = VoiceChannelMember::fromJson(msg.data);
			if(m.userID == discord.userID())
				updateSelfVoiceState(msg);

			else
				voiceChannelMembers.insert(m.userID, m);

			break;
		}

		case ET::voiceStateDelete: {
			const auto voiceData = VoiceChannelMember::fromJson(msg.data);
			voiceChannelMembers.remove(voiceData.userID);
			speakingVoiceChannelMembers.remove(voiceData.userID);
			if(voiceChannelMemberIxOffset >= voiceChannelMembers.size())
				voiceChannelMemberIxOffset = 0;

			/*
			 * Bug workaround - when voice state delete reports the current user, it possibly means that the user has been moved by admin to another voice channel, which does not trigger the VOICE_CHANNEL_SELECT event.
			 * So in this case, we requery everything.
			 * */
			if(voiceData.userID == discord.userID())
				updateChannelMembersData();

			break;
		}

		case ET::speakingStart:
			speakingVoiceChannelMembers.insert(msg.data["user_id"].toString());
			break;

		case ET::speakingStop:
			speakingVoiceChannelMembers.remove(msg.data["user_id"].toString());
			break;

		case ET::voiceSettingsUpdate:
			isMicrophoneMuted = msg.data["mute"].toBool();
			isDeafened = msg.data["deaf"].toBool();
			emit buttonsUpdateRequested();
			break;

		default:
			return;

	}

	emit buttonsUpdateRequested();
}

void DVMPlugin::onInitialized() {
	setGlobalSettingDefault("voiceChannelVolumeButtonStep", 5);
	setGlobalSettingDefault("voiceChannelVolumeEncoderStep", 5);
}

void DVMPlugin::onStreamDeckEventReceived(const QStreamDeckEvent &e) {
	using ET = QStreamDeckEvent::EventType;

	// deviceDidConnect proves that WebSocket registration with Stream Deck has
	// completed. Only then is it safe to begin potentially blocking Discord IPC
	// and OAuth work during a simultaneous PC/Discord/Stream Deck startup.
	if(e.eventType == ET::deviceDidConnect && !discord.isConnected()
			&& !discord.isProcessing() && !discordReconnectTimer_.isActive())
		discordReconnectTimer_.start(0);

	// Try connecting to discord whenever any button is pressed
	if(!discord.isConnected() && !discordConnectTimeoutTimer_.isActive() && (e.eventType == ET::touchTap || e.eventType == ET::keyDown || e.eventType == ET::dialDown || e.eventType == ET::dialUp || e.eventType == ET::dialRotate)) {
		discordConnectTimeoutTimer_.start();
		discordReconnectTimer_.stop();
		connectToDiscord();
	}
}
