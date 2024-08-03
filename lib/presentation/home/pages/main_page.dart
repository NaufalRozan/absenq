import 'package:absenq/presentation/home/pages/attendance_checkout_page.dart';
import 'package:absenq/presentation/home/pages/history_page.dart';
import 'package:absenq/presentation/home/pages/home_page.dart';
import 'package:absenq/presentation/home/pages/setting_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/core.dart';
import '../../../core/helper/radius_calculate.dart';
import '../bloc/get_company/get_company_bloc.dart';
import '../bloc/is_checkedin/is_checkedin_bloc.dart';
import 'attendance_checkin_page.dart';
import 'register_face_attendance_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  double? latitude;
  double? longitude;
  String? faceEmbedding;
  int _selectedIndex = 0;
  final _widgets = [
    const HomePage(),
    const HistoryPage(),
    const SettingPage(),
    const Center(child: Text('This is profile page')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgets,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 10.0),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.06),
              blurRadius: 16.0,
              blurStyle: BlurStyle.outer,
              offset: const Offset(0, -8),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            useLegacyColorScheme: false,
            currentIndex: _selectedIndex,
            onTap: (value) => setState(() => _selectedIndex = value),
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(color: AppColors.primary),
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            elevation: 0,
            items: [
              BottomNavigationBarItem(
                icon: Assets.icons.nav.home.svg(
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 0 ? AppColors.primary : AppColors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Assets.icons.nav.history.svg(
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 1 ? AppColors.primary : AppColors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'History',
              ),
              BottomNavigationBarItem(
                icon: Assets.icons.nav.setting.svg(
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 2 ? AppColors.primary : AppColors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Setting',
              ),
              BottomNavigationBarItem(
                icon: Assets.icons.nav.profile.svg(
                  colorFilter: ColorFilter.mode(
                    _selectedIndex == 3 ? AppColors.primary : AppColors.grey,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (faceEmbedding != null) {
            final isCheckedInBlocState = context.read<IsCheckedinBloc>().state;
            final isCheckedOut = isCheckedInBlocState.maybeWhen(
              orElse: () => false,
              success: (data) => data.isCheckedout,
            );
            final isCheckedIn = isCheckedInBlocState.maybeWhen(
              orElse: () => false,
              success: (data) => data.isCheckedin,
            );

            final companyBlocState = context.read<GetCompanyBloc>().state;
            final latitudePoint = companyBlocState.maybeWhen(
              orElse: () => 0.0,
              success: (data) => double.parse(data.latitude!),
            );
            final longitudePoint = companyBlocState.maybeWhen(
              orElse: () => 0.0,
              success: (data) => double.parse(data.longitude!),
            );
            final radiusPoint = companyBlocState.maybeWhen(
              orElse: () => 0.0,
              success: (data) => double.parse(data.radiusKm!),
            );

            final position = await Geolocator.getCurrentPosition();
            if (position.isMocked) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Anda menggunakan lokasi palsu'),
                  backgroundColor: AppColors.red,
                ),
              );
              return;
            }

            final distanceKm = RadiusCalculate.calculateDistance(
              latitude ?? 0.0,
              longitude ?? 0.0,
              latitudePoint,
              longitudePoint,
            );

            if (distanceKm > radiusPoint) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Anda diluar jangkauan absen'),
                  backgroundColor: AppColors.red,
                ),
              );
              return;
            }

            if (!isCheckedIn) {
              context.push(const AttendanceCheckinPage());
            } else if (!isCheckedOut) {
              context.push(const AttendanceCheckoutPage());
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Anda sudah checkout'),
                  backgroundColor: AppColors.red,
                ),
              );
            }
          } else {
            showModalBottomSheet(
              backgroundColor: AppColors.white,
              context: context,
              builder: (context) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 60.0,
                      height: 8.0,
                      child: Divider(color: AppColors.lightSheet),
                    ),
                    const CloseButton(),
                    const Center(
                      child: Text(
                        'Oops !',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 24.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    const Center(
                      child: Text(
                        'Aplikasi ingin mengakses Kamera',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 36.0),
                    Button.filled(
                      onPressed: () => context.pop(),
                      label: 'Tolak',
                      color: AppColors.secondary,
                    ),
                    const SpaceHeight(16.0),
                    Button.filled(
                      onPressed: () {
                        context.pop();
                        context.push(const RegisterFaceAttendencePage());
                      },
                      label: 'Izinkan',
                    ),
                  ],
                ),
              ),
            );
          }
        },
        backgroundColor:
            Colors.transparent, // Set transparan agar border terlihat
        elevation: 0, // Menghilangkan shadow default FAB
        child: Container(
          width: 56.0, // Lebar FAB
          height: 56.0, // Tinggi FAB
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary, // Warna latar belakang FAB
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.face,
                size: 24.0, color: Colors.white), // Ikon di dalam FAB
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
