#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

class SystemInfo : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString hostname READ hostname NOTIFY infoChanged)
    Q_PROPERTY(QString kernelVersion READ kernelVersion NOTIFY infoChanged)
    Q_PROPERTY(QString yoctoRelease READ yoctoRelease NOTIFY infoChanged)
    Q_PROPERTY(QString applicationVersion READ applicationVersion NOTIFY infoChanged)
    Q_PROPERTY(QString imageVersion READ imageVersion NOTIFY infoChanged)
    Q_PROPERTY(QString uptime READ uptime NOTIFY infoChanged)
    Q_PROPERTY(QString ipAddress READ ipAddress NOTIFY infoChanged)
    Q_PROPERTY(QString machine READ machine NOTIFY infoChanged)
    Q_PROPERTY(QString currentSlot READ currentSlot NOTIFY infoChanged)

public:
    explicit SystemInfo(QObject *parent = nullptr);

    QString hostname() const { return m_hostname; }
    QString kernelVersion() const { return m_kernelVersion; }
    QString yoctoRelease() const { return m_yoctoRelease; }
    QString applicationVersion() const { return m_applicationVersion; }
    QString imageVersion() const { return m_imageVersion; }
    QString uptime() const { return m_uptime; }
    QString ipAddress() const { return m_ipAddress; }
    QString machine() const { return m_machine; }
    QString currentSlot() const { return m_currentSlot; }

    Q_INVOKABLE void refresh();

signals:
    void infoChanged();

private:
    void readStaticInfo();
    void readDynamicInfo();
    static QString readFile(const QString &path);
    static QString formatUptime(double seconds);
    static QString firstIpv4Address();
    static QString osReleaseField(const QString &key);

    QTimer m_timer;
    QString m_hostname;
    QString m_kernelVersion;
    QString m_yoctoRelease;
    QString m_applicationVersion;
    QString m_imageVersion;
    QString m_uptime;
    QString m_ipAddress;
    QString m_machine;
    QString m_currentSlot;
};
