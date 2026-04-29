import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wellness/ui/tset/dashboard.dart';
import 'package:wellness/ui/views/splash/splash_view.dart';
// import 'package:wellness/ui/views/add_schdule_request/add_schedule_request.dart';
// import 'package:wellness/ui/views/admin_side/dashboard/admin_dashboard.dart';
// import 'package:wellness/ui/views/bottom_bar/bottom_bar.dart';
// import 'package:wellness/ui/views/chat_module/chat_list/chat_list.dart';
// import 'package:wellness/ui/views/chat_module/message_screen/message_screen.dart';
// import 'package:wellness/ui/views/goal/goal_screen.dart';
// import 'package:wellness/ui/views/login/login_view.dart';
// import 'package:wellness/ui/views/mark_attendance/mark_attendance.dart';
// import 'package:wellness/ui/views/measurements/measurement_view.dart';
// import 'package:wellness/ui/views/myschedule_user/all_schedules.dart';
// import 'package:wellness/ui/views/myschedule_user/my_schedules.dart';
// import 'package:wellness/ui/views/myschedule_user/myschedule_user.dart';
// import 'package:wellness/ui/views/name/name_view.dart';
// import 'package:wellness/ui/views/question/question_screen.dart';
// import 'package:wellness/ui/views/resgister/register.dart';
// import 'package:wellness/ui/views/splash/splash_view.dart';
// import 'package:wellness/ui/views/trainer/manage_client/screens/client_dashboard_screen.dart';
// import 'package:wellness/ui/views/trainer/progree_tracker/progress_tracker_trainer.dart';
// import 'package:wellness/ui/views/trainer_bottom_bar/trainer_bottom_bar.dart';
// import 'package:wellness/ui/views/trainer_clients/trainer_clients.dart';
// import 'package:wellness/ui/views/trainer_profile/trainer_profile_view.dart';
// import 'package:wellness/ui/views/trainer_scedule/trainer_schedule.dart';
// import 'package:wellness/ui/views/trainer_welcome/trainer_dashboard.dart';
// import 'package:wellness/ui/views/user/nutrition/screens/nutrition_screen.dart';
// import 'package:wellness/ui/views/user/progress_tracker/log/screens/progress_track_screen.dart';
// import 'package:wellness/ui/views/user_releated_data/profile_screen.dart';

import 'core/app_navigator.dart';
import 'core/firebase-service/firebase-service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await NotificationService.initialize();
  // await NotificationService.getToken();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    // Only initialize notifications on real device
    await NotificationService.initialize();
    await NotificationService.getToken();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Dashboard(), // ✅ nothing wrapping this
    );/*MaterialApp(
      title: 'Wellness',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      home: AppNavigator(),
      *//*initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashView(),
        // '/login': (context) => const LoginView(),
        // '/name': (context) => NameScreen(),
        // '/profile': (context) => ProfileScreen(),
        // '/measurement': (context) => MeasurementScreen(),
        // '/goal': (context) => GoalScreen(),
        // '/question': (context) => const QuestionScreen(),
        // '/trainer-profile': (context) => const TrainerProfileView(),
        // '/home': (context) => const MainBottomNav(),
        // '/admin-dashboard': (context) => AdminDashboard(),
        // '/signup': (context) => SignupScreen(),
        // '/trainer-dashboard': (context) => TrainerDashboard(),
        // '/chat-list': (context) => ChatListScreen(),
        // '/message-screen': (context) =>
        //     MessageScreen(name: 'test', chatId: 1, senderId: 1),
        // '/schedule-user': (context) => MyScheduleUserScreen(),
        // '/all-schedule-user': (context) => AllScheduleUserScreen(),
        // '/schedule-trainer': (context) => ScheduleTrainerScreen(),
        // '/my-schedule': (context) => MySchedules(),
        // '/mark-attendance': (context) => AttendanceScreen(),
        // '/add-schedule': (context) => AddScheduleRequest(),
        // //  '/trainer-clients': (context) => TrainerClients(),
        // '/trainer-bottom-bar': (context) => TrainerBottomNav(),
        // '/track-progress-screen': (context) => ProgressTrackScreen(),
        // '/trainer-track-progress-screen': (context) => TrainerProgressTrackScreen(),
        // '/nutrition-screen': (context) => NutritionScreen(),
        // '/client-dashboard-screen': (context) => ClientDashboardScreen(),
      },*//*
    );*/
  }
}
