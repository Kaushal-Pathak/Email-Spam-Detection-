#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QString>
#include <QVariantMap>
#include <QRegularExpression>
#include <QStringList>
#include <QDebug>
#include <QTimer>

class EmailAnalyzer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString emailText READ emailText WRITE setEmailText NOTIFY emailTextChanged)
    Q_PROPERTY(QVariantMap analysisResult READ analysisResult NOTIFY analysisResultChanged)
    Q_PROPERTY(bool isAnalyzing READ isAnalyzing NOTIFY isAnalyzingChanged)
    Q_PROPERTY(double spamScore READ spamScore NOTIFY spamScoreChanged)
    Q_PROPERTY(QString classification READ classification NOTIFY classificationChanged)

public:
    explicit EmailAnalyzer(QObject *parent = nullptr)
        : QObject(parent), m_isAnalyzing(false), m_spamScore(0.0), m_classification("Unknown")
    {
    }

    QString emailText() const { return m_emailText; }
    void setEmailText(const QString &text) {
        if (m_emailText != text) {
            m_emailText = text;
            emit emailTextChanged();
        }
    }

    QVariantMap analysisResult() const { return m_analysisResult; }
    bool isAnalyzing() const { return m_isAnalyzing; }
    double spamScore() const { return m_spamScore; }
    QString classification() const { return m_classification; }

    Q_INVOKABLE void analyzeEmail() {
        if (m_emailText.isEmpty()) {
            qDebug() << "No email text to analyze";
            return;
        }

        m_isAnalyzing = true;
        emit isAnalyzingChanged();

        QTimer::singleShot(500, this, [this]() {
            m_spamScore = calculateSpamScore(m_emailText);
            emit spamScoreChanged();

            if (m_spamScore >= 0.75) {
                m_classification = "HIGH RISK SPAM";
            } else if (m_spamScore >= 0.5) {
                m_classification = "LIKELY SPAM";
            } else if (m_spamScore >= 0.3) {
                m_classification = "SUSPICIOUS";
            } else {
                m_classification = "SAFE";
            }
            emit classificationChanged();

            QVariantMap result;
            result["spamScore"] = m_spamScore;
            result["classification"] = m_classification;
            result["spamKeywords"] = detectSpamKeywords(m_emailText);
            result["suspiciousLinks"] = detectSuspiciousLinks(m_emailText);
            result["hasUrgency"] = checkUrgencyPatterns(m_emailText);
            result["hasPhishingIndicators"] = checkPhishingIndicators(m_emailText);
            result["excessiveCapitals"] = countCapitalizedWords(m_emailText) > 5;
            result["excessivePunctuation"] = containsExcessivePunctuation(m_emailText);
            result["metadata"] = extractEmailMetadata(m_emailText);

            m_analysisResult = result;
            emit analysisResultChanged();

            m_isAnalyzing = false;
            emit isAnalyzingChanged();
            emit analysisCompleted();

            qDebug() << "Analysis completed. Spam Score:" << m_spamScore << "Classification:" << m_classification;
        });
    }

    Q_INVOKABLE void clearAnalysis() {
        m_emailText.clear();
        m_analysisResult.clear();
        m_spamScore = 0.0;
        m_classification = "Unknown";

        emit emailTextChanged();
        emit analysisResultChanged();
        emit spamScoreChanged();
        emit classificationChanged();
    }

signals:
    void emailTextChanged();
    void analysisResultChanged();
    void isAnalyzingChanged();
    void spamScoreChanged();
    void classificationChanged();
    void analysisCompleted();

private:
    QString m_emailText;
    QVariantMap m_analysisResult;
    bool m_isAnalyzing;
    double m_spamScore;
    QString m_classification;

    double calculateSpamScore(const QString &text) {
        double score = 0.0;
        QString lowerText = text.toLower();

        QStringList spamKeywords = detectSpamKeywords(text);
        if (!spamKeywords.isEmpty()) {
            score += 0.3 * qMin(spamKeywords.size() / 5.0, 1.0);
        }

        if (checkPhishingIndicators(text)) {
            score += 0.25;
        }

        if (checkUrgencyPatterns(text)) {
            score += 0.15;
        }

        QStringList suspiciousLinks = detectSuspiciousLinks(text);
        if (!suspiciousLinks.isEmpty()) {
            score += 0.15;
        }

        if (countCapitalizedWords(text) > 5) {
            score += 0.1;
        }

        if (containsExcessivePunctuation(text)) {
            score += 0.05;
        }

        return qMin(score, 1.0);
    }

    QStringList detectSpamKeywords(const QString &text) {
        QString lowerText = text.toLower();
        QStringList foundKeywords;
        QStringList keywords = {
            "congratulations", "winner", "prize", "lottery", "inheritance",
            "urgent", "act now", "limited time", "click here", "free money",
            "nigerian prince", "bank account", "transfer funds", "wire transfer",
            "guaranteed", "risk-free", "no obligation", "double your",
            "make money fast", "work from home", "earn extra cash",
            "viagra", "pharmacy", "prescription", "weight loss",
            "casino", "poker", "gambling"
        };

        for (const QString &keyword : keywords) {
            if (lowerText.contains(keyword)) {
                foundKeywords.append(keyword);
            }
        }

        return foundKeywords;
    }

    QStringList detectSuspiciousLinks(const QString &text) {
        QStringList suspiciousLinks;
        QRegularExpression urlRegex(R"((https?://[^\s]+))");
        QRegularExpressionMatchIterator i = urlRegex.globalMatch(text);

        while (i.hasNext()) {
            QRegularExpressionMatch match = i.next();
            QString url = match.captured(1);

            if (url.contains(QRegularExpression(R"(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})")) || 
                url.contains("bit.ly") || url.contains("tinyurl") || 
                url.contains("@") || 
                url.toLower().contains("login") || url.toLower().contains("verify") ||
                url.toLower().contains("account") || url.toLower().contains("secure")) {
                suspiciousLinks.append(url);
            }
        }

        return suspiciousLinks;
    }

    bool checkUrgencyPatterns(const QString &text) {
        QString lowerText = text.toLower();
        QStringList urgencyKeywords = {
            "urgent", "immediately", "act now", "expires today",
            "limited time", "hurry", "don't miss out", "last chance",
            "expires soon", "time sensitive", "respond now", "within 24 hours"
        };

        for (const QString &keyword : urgencyKeywords) {
            if (lowerText.contains(keyword)) {
                return true;
            }
        }

        return false;
    }

    bool checkPhishingIndicators(const QString &text) {
        QString lowerText = text.toLower();
        QStringList phishingKeywords = {
            "verify your account", "confirm your identity", "suspended account",
            "unusual activity", "security alert", "update payment",
            "verify payment method", "confirm payment", "billing problem",
            "account locked", "reactivate", "validate", "authenticate"
        };

        int matches = 0;
        for (const QString &keyword : phishingKeywords) {
            if (lowerText.contains(keyword)) {
                matches++;
            }
        }

        return matches >= 2; 
    }

    int countCapitalizedWords(const QString &text) {
        QStringList words = text.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);
        int count = 0;

        for (const QString &word : words) {
            if (word.length() > 2 && word == word.toUpper()) {
                count++;
            }
        }

        return count;
    }

    bool containsExcessivePunctuation(const QString &text) {
        int exclamationCount = text.count('!');
        int questionCount = text.count('?');

        return (exclamationCount > 3 || questionCount > 3);
    }

    QVariantMap extractEmailMetadata(const QString &text) {
        QVariantMap metadata;

        QRegularExpression fromRegex(R"(From:\s*([^\n]+))");
        QRegularExpressionMatch fromMatch = fromRegex.match(text);
        if (fromMatch.hasMatch()) {
            metadata["sender"] = fromMatch.captured(1).trimmed();
        }

        QRegularExpression subjectRegex(R"(Subject:\s*([^\n]+))");
        QRegularExpressionMatch subjectMatch = subjectRegex.match(text);
        if (subjectMatch.hasMatch()) {
            metadata["subject"] = subjectMatch.captured(1).trimmed();
        }

        metadata["wordCount"] = text.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts).size();

        metadata["charCount"] = text.length();

        return metadata;
    }
};

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    EmailAnalyzer emailAnalyzer;

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextProperty("emailAnalyzer", &emailAnalyzer);

    const QUrl url(QStringLiteral("qrc:/qt/qml/Main/main.qml"));
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}

#include "main.moc"
