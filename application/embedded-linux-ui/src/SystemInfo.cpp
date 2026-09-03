#include "SystemInfo.h"

#include <QAbstractSocket>
#include <QCoreApplication>
#include <QFile>
#include <QHostInfo>
#include <QNetworkInterface>
#include <QSysInfo>
#include <QTextStream>

SystemInfo::SystemInfo(QObject *parent)
    : QObject(parent)
{
    readStaticInfo();
    readDynamicInfo();
    connect(&m_timer, &QTimer::timeout, this, &SystemInfo::readDynamicInfo);
    m_timer.start(1000);
}

void SystemInfo::refresh()
{
    readStaticInfo();
    readDynamicInfo();
}

QString SystemInfo::readFile(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};
    return QString::fromUtf8(file.readAll()).trimmed();
}

QString SystemInfo::osReleaseField(const QString &key)
{
    QFile file(QStringLiteral("/etc/os-release"));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return {};

    QTextStream stream(&file);
    const QString prefix = key + QLatin1Char('=');
    while (!stream.atEnd()) {
        const QString line = stream.readLine().trimmed();
        if (!line.startsWith(prefix))
            continue;
        QString value = line.mid(prefix.size());
        if (value.startsWith(QLatin1Char('"')) && value.endsWith(QLatin1Char('"')))
            value = value.mid(1, value.size() - 2);
        return value;
    }
    return {};
}

QString SystemInfo::formatUptime(double seconds)
{
    const int total = static_cast<int>(seconds);
    const int hours = total / 3600;
    const int minutes = (total % 3600) / 60;
    const int secs = total % 60;
    return QStringLiteral("%1:%2:%3")
        .arg(hours, 2, 10, QLatin1Char('0'))
        .arg(minutes, 2, 10, QLatin1Char('0'))
        .arg(secs, 2, 10, QLatin1Char('0'));
}

QString SystemInfo::firstIpv4Address()
{
    const auto interfaces = QNetworkInterface::allInterfaces();
    QString fallback;
    for (const QNetworkInterface &iface : interfaces) {
        if (!(iface.flags() & QNetworkInterface::IsUp)
            || !(iface.flags() & QNetworkInterface::IsRunning)
            || (iface.flags() & QNetworkInterface::IsLoopBack)) {
            continue;
        }
        for (const QNetworkAddressEntry &entry : iface.addressEntries()) {
            const QHostAddress ip = entry.ip();
            if (ip.protocol() != QAbstractSocket::IPv4Protocol)
                continue;
            const QString name = iface.name();
            if (name.startsWith(QLatin1String("eth")) || name.startsWith(QLatin1String("en")))
                return ip.toString();
            if (fallback.isEmpty())
                fallback = ip.toString();
        }
    }
    return fallback.isEmpty() ? QStringLiteral("not connected") : fallback;
}

void SystemInfo::readStaticInfo()
{
    m_hostname = QHostInfo::localHostName();
    if (m_hostname.isEmpty())
        m_hostname = readFile(QStringLiteral("/etc/hostname"));
    if (m_hostname.isEmpty())
        m_hostname = QStringLiteral("unknown");

    m_kernelVersion = QSysInfo::kernelVersion();
    m_yoctoRelease = osReleaseField(QStringLiteral("PRETTY_NAME"));
    if (m_yoctoRelease.isEmpty())
        m_yoctoRelease = osReleaseField(QStringLiteral("VERSION"));
    if (m_yoctoRelease.isEmpty())
        m_yoctoRelease = QStringLiteral("unknown");

    m_applicationVersion = QCoreApplication::applicationVersion();
    m_imageVersion = readFile(QStringLiteral("/etc/image-version"));
    if (m_imageVersion.isEmpty())
        m_imageVersion = m_applicationVersion;

    m_machine = readFile(QStringLiteral("/etc/image-machine"));
    if (m_machine.isEmpty())
        m_machine = osReleaseField(QStringLiteral("OPENEMBEDDED_TARGET"));
    if (m_machine.isEmpty())
        m_machine = QSysInfo::currentCpuArchitecture();

    const QString cmdline = readFile(QStringLiteral("/proc/cmdline"));
    if (cmdline.contains(QLatin1String("eld.slot=B")) || cmdline.contains(QLatin1String("root=/dev/mmcblk0p3")))
        m_currentSlot = QStringLiteral("B");
    else if (cmdline.contains(QLatin1String("eld.slot=A")) || cmdline.contains(QLatin1String("root=/dev/mmcblk0p2")))
        m_currentSlot = QStringLiteral("A");
    else
        m_currentSlot = QStringLiteral("A (host)");

    emit infoChanged();
}

void SystemInfo::readDynamicInfo()
{
    const QString raw = readFile(QStringLiteral("/proc/uptime"));
    const double seconds = raw.section(QLatin1Char(' '), 0, 0).toDouble();
    m_uptime = raw.isEmpty() ? QStringLiteral("--:--:--") : formatUptime(seconds);
    m_ipAddress = firstIpv4Address();
    emit infoChanged();
}
