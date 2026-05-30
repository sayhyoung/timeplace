# 앱 서명키 보관 메모

## 생성된 파일

- 업로드 키스토어: `android/app/upload-keystore.jks`
- 서명 설정 파일: `android/key.properties`

두 파일은 앱 업데이트 배포에 필요합니다.
외부 저장소, GitHub, 메신저에 공유하지 말고 별도 백업 드라이브나 비밀번호 관리자에 안전하게 보관하세요.

## 현재 Gradle 설정

`android/app/build.gradle.kts`의 release 빌드는 `android/key.properties`가 있을 때 업로드 키로 서명합니다.
키 파일이 없는 환경에서는 debug 서명으로 fallback되지만, 플레이스토어 업로드용 AAB는 반드시 이 키가 있는 환경에서 빌드해야 합니다.

## 플레이스토어 업로드 빌드

```bash
flutter build appbundle --release --dart-define=KAKAO_REST_API_KEY=발급받은_키
```

결과 파일:

```text
build/app/outputs/bundle/release/app-release.aab
```

## 주의

`android/key.properties`에는 비밀번호가 들어 있습니다.
`android/app/upload-keystore.jks`와 `android/key.properties`를 잃어버리면 같은 앱의 업데이트 배포가 어려워질 수 있습니다.
