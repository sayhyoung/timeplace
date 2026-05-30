/// 상황별 메모 토퍼 템플릿. 선택 시 사용자의 메모 필드에 채워진다.
enum TopperCategory {
  meal,
  workout,
  study,
  daily,
  travel,
  proof;

  String get title {
    switch (this) {
      case TopperCategory.meal:
        return '식단';
      case TopperCategory.workout:
        return '운동';
      case TopperCategory.study:
        return '스터디';
      case TopperCategory.daily:
        return '일상';
      case TopperCategory.travel:
        return '여행';
      case TopperCategory.proof:
        return '인증';
    }
  }

  String get emoji {
    switch (this) {
      case TopperCategory.meal:
        return '🥗';
      case TopperCategory.workout:
        return '🏃';
      case TopperCategory.study:
        return '✏️';
      case TopperCategory.daily:
        return '🫧';
      case TopperCategory.travel:
        return '🧳';
      case TopperCategory.proof:
        return '🏷️';
    }
  }
}

class TopperTemplate {
  final TopperCategory category;
  final String text;
  const TopperTemplate(this.category, this.text);
}

class TopperTemplates {
  static const List<TopperTemplate> all = [
    // 식단
    TopperTemplate(TopperCategory.meal, '🥣 오늘의 아침 ⋆⁺₊'),
    TopperTemplate(TopperCategory.meal, '🍱 점심 기록 ✦'),
    TopperTemplate(TopperCategory.meal, '🌙 저녁 한 끼'),
    TopperTemplate(TopperCategory.meal, '🥗 식단 체크 ✓'),
    TopperTemplate(TopperCategory.meal, '🍓 가벼운 한 접시'),
    TopperTemplate(TopperCategory.meal, '🥚 단백질 충전'),
    TopperTemplate(TopperCategory.meal, '☕ 카페 타임'),
    TopperTemplate(TopperCategory.meal, '🍪 간식도 기록'),
    TopperTemplate(TopperCategory.meal, '🏠 홈쿡 데이'),
    TopperTemplate(TopperCategory.meal, '✨ 맛있게 완료'),
    TopperTemplate(TopperCategory.meal, '🍽️ 오늘의 한 끼'),
    TopperTemplate(TopperCategory.meal, '🥤 수분 채우기'),

    // 운동
    TopperTemplate(TopperCategory.workout, '💪 운동 완료 ✦'),
    TopperTemplate(TopperCategory.workout, '🏃 러닝 체크'),
    TopperTemplate(TopperCategory.workout, '🧘 요가 루틴'),
    TopperTemplate(TopperCategory.workout, '🏋️ 헬스장 출석'),
    TopperTemplate(TopperCategory.workout, '🚴 라이딩 데이'),
    TopperTemplate(TopperCategory.workout, '⛰️ 산책보다 멀리'),
    TopperTemplate(TopperCategory.workout, '🔥 오늘도 해냈다'),
    TopperTemplate(TopperCategory.workout, '⏱️ 땀 한 스푼'),
    TopperTemplate(TopperCategory.workout, '🩵 몸이 가벼운 날'),
    TopperTemplate(TopperCategory.workout, '🎧 운동 플레이리스트'),
    TopperTemplate(TopperCategory.workout, '🌿 스트레칭 완료'),
    TopperTemplate(TopperCategory.workout, '🏊 수영 기록'),
    TopperTemplate(TopperCategory.workout, '🎾 현재 코트 상태'),
    TopperTemplate(TopperCategory.workout, '🎾 코트 정리 완료'),
    TopperTemplate(TopperCategory.workout, '🎾 시합 진행 중'),
    TopperTemplate(TopperCategory.workout, '🎾 오늘의 연습 기록'),
    TopperTemplate(TopperCategory.workout, '🎾 코트 위 힐링 타임'),
    TopperTemplate(TopperCategory.workout, '🎾 서브 연습 완료'),
    TopperTemplate(TopperCategory.workout, '🎾 랠리 기록 저장'),
    TopperTemplate(TopperCategory.workout, '🎾 게임 전 워밍업'),
    TopperTemplate(TopperCategory.workout, '🎾 레슨 인증 완료'),
    TopperTemplate(TopperCategory.workout, '⛳ 필드 현재 상태'),
    TopperTemplate(TopperCategory.workout, '⛳ 라운딩 중'),
    TopperTemplate(TopperCategory.workout, '⛳ 그린 상태 확인'),
    TopperTemplate(TopperCategory.workout, '⛳ 티오프 준비 완료'),
    TopperTemplate(TopperCategory.workout, '⛳ 필드에서 충전 완료'),
    TopperTemplate(TopperCategory.workout, '⛳ 오늘의 스윙 기록'),
    TopperTemplate(TopperCategory.workout, '⛳ 퍼팅 연습 완료'),
    TopperTemplate(TopperCategory.workout, '⛳ 전반 홀 기록'),
    TopperTemplate(TopperCategory.workout, '⛳ 후반 홀 기록'),
    TopperTemplate(TopperCategory.workout, '⛳ 라운딩 인증샷'),

    // 스터디
    TopperTemplate(TopperCategory.study, '📚 오늘의 공부'),
    TopperTemplate(TopperCategory.study, '✏️ 집중 모드 ON'),
    TopperTemplate(TopperCategory.study, '📝 필기 완료'),
    TopperTemplate(TopperCategory.study, '📖 독서 기록'),
    TopperTemplate(TopperCategory.study, '💡 배운 것 저장'),
    TopperTemplate(TopperCategory.study, '🧠 자기계발 중'),
    TopperTemplate(TopperCategory.study, '🏛️ 도서관 출석'),
    TopperTemplate(TopperCategory.study, '🎧 인강 체크'),
    TopperTemplate(TopperCategory.study, '⭐ 시험 D-1'),
    TopperTemplate(TopperCategory.study, '✅ 챌린지 진행 중'),
    TopperTemplate(TopperCategory.study, '🌙 늦은 공부'),
    TopperTemplate(TopperCategory.study, '📌 오늘의 목표'),

    // 일상
    TopperTemplate(TopperCategory.daily, '🫧 오늘의 한 컷'),
    TopperTemplate(TopperCategory.daily, '☀️ 좋은 하루'),
    TopperTemplate(TopperCategory.daily, '🌷 소소한 순간'),
    TopperTemplate(TopperCategory.daily, '🤍 마음에 저장'),
    TopperTemplate(TopperCategory.daily, '✨ 오늘의 기록'),
    TopperTemplate(TopperCategory.daily, '🧺 평범해서 좋아'),
    TopperTemplate(TopperCategory.daily, '🌙 굿나잇 로그'),
    TopperTemplate(TopperCategory.daily, '🚶 산책 중'),
    TopperTemplate(TopperCategory.daily, '🪞 OOTD 기록'),
    TopperTemplate(TopperCategory.daily, '🍀 작은 행운'),
    TopperTemplate(TopperCategory.daily, '📷 찰칵 저장'),
    TopperTemplate(TopperCategory.daily, '💛 행복한 순간'),

    // 여행
    TopperTemplate(TopperCategory.travel, '🧳 여행 기록'),
    TopperTemplate(TopperCategory.travel, '✈️ 출발의 순간'),
    TopperTemplate(TopperCategory.travel, '🌊 오늘의 풍경'),
    TopperTemplate(TopperCategory.travel, '🏨 쉬어가는 날'),
    TopperTemplate(TopperCategory.travel, '🚗 드라이브 로그'),
    TopperTemplate(TopperCategory.travel, '🍴 맛집 저장'),
    TopperTemplate(TopperCategory.travel, '🗺️ 여기 다녀감'),
    TopperTemplate(TopperCategory.travel, '🎞️ 추억 한 장'),
    TopperTemplate(TopperCategory.travel, '🌴 휴가 모드'),
    TopperTemplate(TopperCategory.travel, '⛅ 낯선 하늘'),
    TopperTemplate(TopperCategory.travel, '🏞️ 뷰 맛집'),
    TopperTemplate(TopperCategory.travel, '🧭 다음 목적지'),

    // 인증
    TopperTemplate(TopperCategory.proof, '✅ 인증 완료'),
    TopperTemplate(TopperCategory.proof, '⏰ 출근 도장'),
    TopperTemplate(TopperCategory.proof, '🌙 퇴근 완료'),
    TopperTemplate(TopperCategory.proof, '📍 현장 확인'),
    TopperTemplate(TopperCategory.proof, '🗂️ 점검 완료'),
    TopperTemplate(TopperCategory.proof, '🤝 회의 기록'),
    TopperTemplate(TopperCategory.proof, '🎯 미션 클리어'),
    TopperTemplate(TopperCategory.proof, '🧾 증빙 컷'),
    TopperTemplate(TopperCategory.proof, '📌 약속 완료'),
    TopperTemplate(TopperCategory.proof, '🏷️ 일일 체크'),
    TopperTemplate(TopperCategory.proof, '🔖 오늘의 확인'),
    TopperTemplate(TopperCategory.proof, '🪪 기록 남김'),
  ];

  static List<TopperTemplate> byCategory(TopperCategory c) =>
      all.where((t) => t.category == c).toList();
}
