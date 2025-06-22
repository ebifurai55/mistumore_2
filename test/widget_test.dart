import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mitsumore_2/main.dart';
import 'package:mitsumore_2/providers/user_provider.dart';

void main() {
  group('ミツモア風アプリ テスト', () {
    testWidgets('アプリが正常に起動する', (WidgetTester tester) async {
      // アプリをビルドして起動
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
          child: const MyApp(),
        ),
      );

      // アプリタイトルが表示されることを確認
      expect(find.text('ミツモア'), findsOneWidget);
    });

    testWidgets('ログイン画面が表示される', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
          child: const MyApp(),
        ),
      );

      // ログイン画面の要素を確認
      expect(find.text('ログイン'), findsWidgets);
      expect(find.text('新規登録'), findsWidgets);
    });

    testWidgets('メール入力フィールドが存在する', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
          child: const MyApp(),
        ),
      );

      // メール入力フィールドを確認
      expect(find.byType(TextFormField), findsWidgets);
    });
  });

  group('UserProviderテスト', () {
    test('UserProviderが正常に初期化される', () {
      final userProvider = UserProvider();
      
      expect(userProvider.user, isNull);
      expect(userProvider.isLoading, isFalse);
      expect(userProvider.isLoggedIn, isFalse);
    });
  });
} 