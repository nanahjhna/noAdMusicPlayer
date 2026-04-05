import 'package:flutter/material.dart';

class AppStrings {
  static String get(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;

    const data = {
      "ko": {
        'app_name': '광고 없는 음악',
        "logo": "",
        "googleLogin": "Google로 로그인",

        "leaveTeamError": "팀 탈퇴 중 오류가 발생했습니다.",
        "leaveTeamSuccess": "팀을 탈퇴했습니다.",
        "noNotifications": "알림이 없습니다",
        "participating": "참가 중",
        "noTeam": "속한 팀이 없습니다.",

        "close": "닫기",
        "no": "아니오",
        "yes": "예",
        "join": "참가",
        "participate": "참여",
        "leave": "탈퇴",
        "confirm": "확인",

        "enterCode": "6자리 코드를 입력하세요.",
        "noSearchResult": "검색된 팀이 없습니다.",
        "confirmLeaveTeam": "이 팀을 탈퇴하시겠습니까?",
        "joinApproved": "팀 가입이 승인되었습니다.",
        "confirmJoinTeam": "팀에 참가하시겠습니까?",
        "waitingApproval": "현재 가입 승인 대기 중입니다.",

        "createNewTeam": "새 팀 생성하기",
        "approvalTitle": "가입 승인",
        "applyComplete": "가입 신청 완료",
        "searchResult": "검색 결과",
        "teamJoin": "팀 목록",
        "teamLeave": "팀 탈퇴",

        // TeamJoinScreen
        "teamJoinTitle": "팀 참가",
        "teamJoinEnterCodeTitle": "팀 코드를 입력하세요",
        "teamJoinEnterCodeSubtitle": "팀장이 공유한 6자리 코드를 입력하여 워크스페이스에 참여하세요.",
        "teamVerified": "인증된 팀",
        "teamNamePreview": "팀 확인됨: noAdMusicPlayer Design",
        "teamActiveMembers": "6명 활동 중",
        "joinComplete": "참가 완료",
        "cancel": "취소",

        // TeamCreateScreen
        "teamCreateTitle": "팀 생성",
        "teamCreateAdminInfo": "관리자로 생성됩니다",
        "teamName": "팀 이름",
        "teamDescription": "팀 설명",
        "teamCreateComplete": "생성 완료",
        "errorTeamNameEmpty": "팀 이름을 입력하세요.",
        "errorOccurred": "에러 발생: ",

        // settings
        "languageSelect": "언어 선택",
        "korean": "한국어",
        "english": "English",
        "japanese": "日本語",
        "logout": "로그아웃",
        "teamHeader": "소속 팀",
        "deleteTeam": "팀 삭제",
        "leaveTeam": "팀 탈퇴",
        "editTeamName": "팀 이름 수정",
        "save": "저장",
        "delete": "삭제",
        "deleteTeamConfirm": "정말로 팀을 삭제하시겠습니까?",
        "languageSettings": "언어 설정",
        "code": "코드",
        "copied": "복사되었습니다",
        "home": "홈",
        "members": "멤버",
        "fees": "내역",
        "settings": "설정",
        "settingsLoadError": "설정 로드 오류",

        // MemberModal
        "updateRole": "권한 수정",
        "admin": "관리자",
        "member": "일반",
        "update": "수정",
        "deleteMember": "멤버 삭제",

        // Member
        'memberList': '회원 일람',
        'noMembers': '멤버가 없습니다',
        'me': '나',
        'owner': '팀장',
        'pending': '대기',

        // home
        'totalIncome': '총 수입',
        'totalExpense': '총 지출',
        'balance': '현재 잔액',
        'notifications': '알림',
        'startDate': '시작일',
        'endDate': '종료일',
        'noData': '조회된 데이터가 없습니다.',
        'yearMonth': '연월',
        'income': '수입',
        'expense': '지출',
        'difference': '차액',
        'currency': '원',

        // feesModal
        'add_entry': '내역 추가',
        'type': '구분',
        'item_name': '항목명',
        'item_name_hint': '예: 사무용품 구매',
        'amount': '금액',
        'date': '날짜',
        'remarks': '비고',
        'remarks_hint': '기타 참고사항',

        // fees
        'currentMonth': '년 월',
        'addTransaction': '내역 추가',
        'description': '항목명',
        'expenseType': '지출',
        'incomeType': '수입',

        // login
        "login_google_continue": "Google 로 로그인하기",
        "login_google_description": "Google 계정을 사용하여 안전하게 시작하세요",
        "login_terms_prefix": "Google 계정으로 로그인함으로써 귀하는 다음 사항에 동의하게 됩니다",
        "login_terms_service": "서비스 이용약관",
        "login_terms_and": "및",
        "login_terms_privacy": "개인정보 처리방침",
        "language": "언어",

        "welcome_title": "환영합니다 🎉",
        "welcome_message": "가입해주셔서 감사합니다! 팀을 만들고 정산을 시작해보세요.",
        "guestLogin": "시작하기",
        "welcomeUser": "안녕하세요, {name}님!",
        "forChild": "아이용 (추후 기능 제공 예정)",
        "forParent": "보호자용",
        "childScreen": "아이용 화면",
        "gallery": "갤러리",
        "setEdit": "세트편집"
      },

      "en": {
        'app_name': 'No Ads Music',
        "logo": "",
        "googleLogin": "Sign in with Google",

        "leaveTeamError": "An error occurred while leaving the team.",
        "leaveTeamSuccess": "You have left the team.",
        "noNotifications": "No notifications",
        "participating": "Participating",
        "noTeam": "You are not in any team.",

        "close": "Close",
        "no": "No",
        "yes": "Yes",
        "join": "Join",
        "participate": "Participate",
        "leave": "Leave",
        "confirm": "Confirm",

        "enterCode": "Please enter the 6-digit code.",
        "noSearchResult": "No teams found.",
        "confirmLeaveTeam": "Do you want to leave this team?",
        "joinApproved": "Your team join request has been approved.",
        "confirmJoinTeam": "Do you want to join this team?",
        "waitingApproval": "Your join request is pending approval.",

        "createNewTeam": "Create New Team",
        "approvalTitle": "Join Approval",
        "applyComplete": "Application Submitted",
        "searchResult": "Search Results",
        "teamJoin": "Join Team",
        "teamLeave": "Leave Team",

        "teamJoinTitle": "Join Team",
        "teamJoinEnterCodeTitle": "Enter Team Code",
        "teamJoinEnterCodeSubtitle":
            "Enter the 6-digit code shared by the team leader to join the workspace.",
        "teamVerified": "Verified Team",
        "teamNamePreview": "Team Confirmed: noAdMusicPlayer Design",
        "teamActiveMembers": "6 members active",
        "joinComplete": "Complete",
        "cancel": "Cancel",

        "teamCreateTitle": "Create Team",
        "teamCreateAdminInfo": "Will be created as admin",
        "teamName": "Team Name",
        "teamDescription": "Team Description",
        "teamCreateComplete": "Create",
        "errorTeamNameEmpty": "Please enter a team name.",
        "errorOccurred": "Error: ",

        "languageSelect": "Select Language",
        "korean": "Korean",
        "english": "English",
        "japanese": "Japanese",
        "logout": "Logout",
        "teamHeader": "My Team",
        "deleteTeam": "Delete Team",
        "leaveTeam": "Leave Team",
        "editTeamName": "Edit Team Name",
        "save": "Save",
        "delete": "Delete",
        "deleteTeamConfirm": "Are you sure you want to delete the team?",
        "languageSettings": "Language Settings",
        "code": "Code",
        "copied": "Copied",
        "home": "Home",
        "members": "Members",
        "fees": "Fees",
        "settings": "Settings",
        "settingsLoadError": "Failed to load settings",

        // MemberModal
        "updateRole": "Edit Role",
        "admin": "Admin",
        "member": "Member",
        "update": "Update",
        "deleteMember": "Remove Member",

        // Member
        'memberList': 'Members',
        'noMembers': 'No members',
        'me': 'Me',
        'owner': 'Owner',
        'pending': 'Pending',

        // home
        'totalIncome': 'Total Income',
        'totalExpense': 'Total Expense',
        'balance': 'Current Balance',
        'notifications': 'Notifications',
        'startDate': 'Start Date',
        'endDate': 'End Date',
        'noData': 'No data available',
        'yearMonth': 'Year-Month',
        'income': 'Income',
        'expense': 'Expense',
        'difference': 'Difference',
        'currency': '₩',

        // feesModal
        'add_entry': 'Add Entry',
        'type': 'Type',
        'item_name': 'Item Name',
        'item_name_hint': 'Ex: Office Supplies',
        'amount': 'Amount',
        'date': 'Date',
        'remarks': 'Remarks',
        'remarks_hint': 'Other notes',

        // fees
        'currentMonth': 'Year-Month',
        'addTransaction': 'Add Transaction',
        'description': 'Description',
        'expenseType': 'Expense',
        'incomeType': 'Income',

        // login
        "login_google_continue": "Continue with Google",
        "login_google_description": "Start safely using your Google account",
        "login_terms_prefix":
            "By signing in with Google, you agree to the following",
        "login_terms_service": "Terms of Service",
        "login_terms_and": "and",
        "login_terms_privacy": "Privacy Policy",
        "language": "Language",

        "welcome_title": "Welcome 🎉",
        "welcome_message": "Thanks for joining! Create your first team and start splitting expenses.",
        "guestLogin": "Start",
        "welcomeUser": "Hello, {name}!",
        "forChild": "For Child (Coming Soon)",
        "forParent": "For Guardian",
        "childScreen": "Child Screen",
        "gallery": "Gallery",
        "setEdit": "Edit Set"
      },

      "ja": {
        'app_name': '広告なし音楽',
        "logo": "",
        "googleLogin": "Googleでログイン",

        "leaveTeamError": "チーム退会中にエラーが発生しました。",
        "leaveTeamSuccess": "チームを退会しました。",
        "noNotifications": "通知はありません",
        "participating": "参加中",
        "noTeam": "所属しているチームがありません。",

        "close": "閉じる",
        "no": "いいえ",
        "yes": "はい",
        "join": "参加",
        "participate": "参加する",
        "leave": "退会",
        "confirm": "確認",

        "enterCode": "6桁のコードを入力してください。",
        "noSearchResult": "検索結果がありません。",
        "confirmLeaveTeam": "このチームを退会しますか？",
        "joinApproved": "チーム参加が承認されました。",
        "confirmJoinTeam": "このチームに参加しますか？",
        "waitingApproval": "現在承認待ちです。",

        "createNewTeam": "新しいチームを作成",
        "approvalTitle": "参加承認",
        "applyComplete": "申請完了",
        "searchResult": "検索結果",
        "teamJoin": "チーム一覧",
        "teamLeave": "チーム退会",

        "teamJoinTitle": "チーム参加",
        "teamJoinEnterCodeTitle": "チームコードを入力してください",
        "teamJoinEnterCodeSubtitle": "チームリーダーが共有した6桁のコードを入力してワークスペースに参加してください。",
        "teamVerified": "認証済みチーム",
        "teamNamePreview": "確認済みチーム: noAdMusicPlayer Design",
        "teamActiveMembers": "6人が活動中",
        "joinComplete": "参加完了",
        "cancel": "キャンセル",

        "teamCreateTitle": "チーム作成",
        "teamCreateAdminInfo": "管理者として作成されます",
        "teamName": "チーム名",
        "teamDescription": "チームの説明",
        "teamCreateComplete": "作成完了",
        "errorTeamNameEmpty": "チーム名を入力してください。",
        "errorOccurred": "エラー発生: ",

        "languageSelect": "言語を選択",
        "korean": "韓国語",
        "english": "英語",
        "japanese": "日本語",
        "logout": "ログアウト",
        "teamHeader": "所属チーム",
        "deleteTeam": "チームを削除",
        "leaveTeam": "チームを退会",
        "editTeamName": "チーム名を編集",
        "save": "保存",
        "delete": "削除",
        "deleteTeamConfirm": "本当にチームを削除しますか？",
        "languageSettings": "言語設定",
        "code": "コード",
        "copied": "コピーしました",
        "home": "ホーム",
        "members": "メンバー",
        "fees": "会費",
        "settings": "設定",
        "settingsLoadError": "設定の読み込みに失敗しました",

        // MemberModal
        "updateRole": "権限編集",
        "admin": "管理者",
        "member": "一般",
        "update": "更新",
        "deleteMember": "メンバー削除",

        // Member
        'memberList': 'メンバー一覧',
        'noMembers': 'メンバーはいません',
        'me': '自分',
        'owner': 'オーナー',
        'pending': '保留',

        // home
        'totalIncome': '総収入',
        'totalExpense': '総支出',
        'balance': '現在残高',
        'notifications': '通知',
        'startDate': '開始日',
        'endDate': '終了日',
        'noData': 'データがありません。',
        'yearMonth': '年月',
        'income': '収入',
        'expense': '支出',
        'difference': '差額',
        'currency': '円',

        // feesModal
        'add_entry': '取引追加',            // Add Entry → 取引追加
        'type': '種類',                     // Type → 種類
        'item_name': '項目名',               // Item Name → 項目名
        'item_name_hint': '例: 事務用品',     // Ex: Office Supplies → 例: 事務用品
        'amount': '金額',                    // Amount → 金額
        'date': '日付',                      // Date → 日付
        'remarks': '備考',                   // Remarks → 備考
        'remarks_hint': 'その他の参考事項',   // Other notes → その他の参考事項

        // fees
        'currentMonth': '年月',
        'addTransaction': '取引追加',
        'description': '項目名',
        'expenseType': '支出',
        'incomeType': '収入',

        // login
        "login_google_continue": "Google アカウントでログイン",
        "login_google_description": "Google アカウントで安全に開始",
        "login_terms_prefix": "Google アカウントでログインすると、次の内容に同意したことになります",
        "login_terms_service": "利用規約",
        "login_terms_and": "および",
        "login_terms_privacy": "プライバシーポリシー",
        "language": "言語",

        "welcome_title": "ようこそ 🎉",
        "welcome_message": "ご登録ありがとうございます。チームを作成して精算を始めましょう。",
        "guestLogin": "アプリを始まる",
        "welcomeUser": "こんにちは、{name}さん！",
        "forChild": "子供用（後日提供予定）",
        "forParent": "保護者用",
        "childScreen": "子供用画面",
        "gallery": "ギャラリー",
        "setEdit": "セット編集"
      },
    };

    return data[lang]?[key] ?? key;
  }
}
