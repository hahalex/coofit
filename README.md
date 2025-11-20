# Практическая работа №5 — План публикации приложения

## 1. План монетизации и публикации приложения

### 1.1. Модель монетизации

#### **Freemium-модель (бесплатная версия + премиум-функции)**
Бесплатная версия включает:
- подсчёт шагов
- подсчёт калорий
- отслеживание воды
- личный профиль
- базовые графики

Премиум-подписка может включать:
- расширенные графики
- персональные рекомендации
- персональные цели
- автоматические напоминания
- экспорт данных
- облачная синхронизация
- кастомные темы

Стоимость:
- **50₽ / месяц**
- **500₽ / год**

#### **Покупки внутри приложения (one-time)**
- темы интерфейса
- расширенная аналитика
- наборы тренировок

#### **Реклама**
Только в бесплатной версии:
- один баннер AdMob
- возможность убрать рекламу через подписку

---

### 1.2. План публикации
1. Создать аккаунт Google Play Developer (25$).
2. Подготовить материалы:
   - иконка 512x512
   - скриншоты
   - описание
   - политика конфиденциальности
3. Собрать релизный APK/AAB.
4. Создать приложение в Google Play Console.
5. Настроить:
   - возрастной рейтинг
   - разрешения
   - категорию
6. Загрузить AAB.
7. Пройти проверку.
8. Опубликовать.

---

## 2. Инструкция по сборке APK в командной строке

### 2.1. Создание keystore
```
keytool -genkey -v -keystore my-release-key.keystore -alias upload \
-keyalg RSA -keysize 2048 -validity 10000
```
Положить файл в:
```
android/app/my-release-key.keystore
```

### 2.2. Файл key.properties
Создать `android/key.properties`:
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=my-release-key.keystore
```

### 2.3. Настройка build.gradle
```
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
   signingConfigs {
      release {
         keyAlias keystoreProperties["keyAlias"]
         keyPassword keystoreProperties["keyPassword"]
         storeFile keystoreProperties["storeFile"] ? file(keystoreProperties["storeFile"]) : null
         storePassword keystoreProperties["storePassword"]
      }
   }

   buildTypes {
      release {
         signingConfig signingConfigs.release
         minifyEnabled false
      }
   }
}
```

### 2.4. Сборка релизного APK
```
flutter build apk --release
```
APK появится здесь:
```
build/app/outputs/flutter-apk/app-release.apk
```

### 2.5. Сборка AAB (для Google Play)
```
flutter build appbundle --release
```
Файл будет:
```
build/app/outputs/bundle/release/app-release.aab
```

---

## 3. Безопасность приложения

### 3.1. Локальная безопасность данных
- хранение настроек в SharedPreferences
- отсутствие отправки данных на сервер
- отсутствуют секретные ключи в коде

### 3.2. Безопасность сборки
- подпись keystore
- невозможность подделать сборку

### 3.3. Защита пользовательских данных
- только необходимые разрешения
- прозрачная политика конфиденциальности
- отсутствие ненужного сбора данных

### 3.4. Безопасность библиотек
- обновляемые официальные пакеты
- отсутствие устаревших зависимостей
