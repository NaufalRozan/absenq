import 'dart:async';

import 'package:absenq/core/helper/radius_calculate.dart';
import 'package:absenq/data/datasources/auth_local_datasource.dart';
import 'package:absenq/presentation/home/bloc/get_company/get_company_bloc.dart';
import 'package:absenq/presentation/home/bloc/is_checkedin/is_checkedin_bloc.dart';
import 'package:absenq/presentation/home/pages/attendance_checkin_page.dart';
import 'package:absenq/presentation/home/pages/attendance_checkout_page.dart';
import 'package:absenq/presentation/home/pages/location_page.dart';
import 'package:absenq/presentation/home/pages/permission_page.dart';
import 'package:absenq/presentation/home/pages/register_face_attendance_page.dart';
import 'package:absenq/presentation/home/widgets/clock.dart';
import 'package:absenq/presentation/home/widgets/menu_button.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:location/location.dart';

import '../../../core/core.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? faceEmbedding;

  @override
  void initState() {
    super.initState();
    _initializeFaceEmbedding();
    context.read<IsCheckedinBloc>().add(const IsCheckedinEvent.isCheckedIn());
    context.read<GetCompanyBloc>().add(const GetCompanyEvent.getCompany());
    getCurrentPosition();
  }

  void showCupertinoAlertDialog(BuildContext context, String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Peringatan'),
          content: Text(message),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  double? latitude;
  double? longitude;

  Future<void> getCurrentPosition() async {
    try {
      Location location = Location();

      bool serviceEnabled;
      PermissionStatus permissionGranted;
      LocationData locationData;

      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      locationData = await location.getLocation();
      latitude = locationData.latitude;
      longitude = locationData.longitude;

      setState(() {});
    } on PlatformException catch (e) {
      if (e.code == 'IO_ERROR') {
        debugPrint(
            'A network error occurred trying to lookup the supplied coordinates: ${e.message}');
      } else {
        debugPrint('Failed to lookup coordinates: ${e.message}');
      }
    } catch (e) {
      debugPrint('An unknown error occurred: $e');
    }
  }

  Future<void> _initializeFaceEmbedding() async {
    try {
      final authData = await AuthLocalDatasource().getAuthData();
      setState(() {
        faceEmbedding = authData?.user?.faceEmbedding;
      });
    } catch (e) {
      // Tangani error di sini jika ada masalah dalam mendapatkan authData
      print('Error fetching auth data: $e');
      setState(() {
        faceEmbedding = null; // Atur faceEmbedding ke null jika ada kesalahan
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return SafeArea(
      child: Scaffold(
        backgroundColor: AppColors.light,
        body: SingleChildScrollView(
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 3.2,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32.0),
                        bottomRight: Radius.circular(32.0),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 20),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 6.0,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: size.width / 30,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 2.0),
                                    Text(
                                      "PT. Dua Langkah Bersama",
                                      style: TextStyle(
                                        color: AppColors.white,
                                        fontSize: size.width / 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.notifications,
                                size: size.width / 15,
                                color: AppColors.white,
                              ),
                            ],
                          ),
                          SizedBox(height: size.height / 40),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(50.0),
                                    child: Image.network(
                                      'https://i.pinimg.com/originals/1b/14/53/1b14536a5f7e70664550df4ccaa5b231.jpg',
                                      width: 50.0,
                                      height: 50.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(width: 12.0),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      FutureBuilder(
                                        future:
                                            AuthLocalDatasource().getAuthData(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text('Loading...');
                                          } else {
                                            final user = snapshot.data?.user;
                                            final names =
                                                user?.name?.split(' ') ?? [];
                                            final firstName = names.isNotEmpty
                                                ? names[0]
                                                : '';
                                            final lastName = names.length > 1
                                                ? names[1]
                                                : '';
                                            final position = user?.position ??
                                                'Unknown Role'; // Mengambil peran pengguna

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$firstName $lastName', // Menampilkan nama depan dan nama belakang
                                                  style: TextStyle(
                                                    fontSize: size.width / 25,
                                                    color: AppColors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  maxLines: 2,
                                                ),
                                                Text(
                                                  position,
                                                  style: TextStyle(
                                                    color: AppColors.white,
                                                    fontSize: size.width / 30,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                              const ClockWidget(),
                            ],
                          ),
                          SizedBox(height: size.height / 40),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10.0),
                                ),
                              ),
                            ),
                            onPressed: () {
                              context.push(LocationPage(
                                latitude: latitude,
                                longitude: longitude,
                              ));
                            },
                            child: Text(
                              "Lihat Lokasi",
                              style: TextStyle(
                                fontSize: size.width / 25,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Layanan",
                                style: TextStyle(
                                  fontSize: size.width / 25,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: size.height / 50),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 13.0),
                                width: size.width,
                                decoration: BoxDecoration(
                                  color: AppColors.light,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        BlocBuilder<GetCompanyBloc,
                                            GetCompanyState>(
                                          builder: (context, state) {
                                            final latitudePoint =
                                                state.maybeWhen(
                                              orElse: () => 0.0,
                                              success: (data) =>
                                                  double.parse(data.latitude!),
                                            );
                                            final longitudePoint =
                                                state.maybeWhen(
                                              orElse: () => 0.0,
                                              success: (data) =>
                                                  double.parse(data.longitude!),
                                            );
                                            final radiusPoint = state.maybeWhen(
                                              orElse: () => 0.0,
                                              success: (data) =>
                                                  double.parse(data.radiusKm!),
                                            );

                                            return BlocConsumer<IsCheckedinBloc,
                                                IsCheckedinState>(
                                              listener: (context, state) {
                                                // Optional listener implementation
                                              },
                                              builder:
                                                  (context, isCheckedinState) {
                                                final isCheckin =
                                                    isCheckedinState.maybeWhen(
                                                  orElse: () => false,
                                                  success: (data) =>
                                                      data.isCheckedin,
                                                );

                                                return GestureDetector(
                                                  onTap: () async {
                                                    // Deteksi lokasi palsu
                                                    final position =
                                                        await Geolocator
                                                            .getCurrentPosition();

                                                    if (position.isMocked) {
                                                      showCupertinoAlertDialog(
                                                          context,
                                                          'Anda menggunakan lokasi palsu');
                                                      return;
                                                    }

                                                    // Hitung jarak
                                                    final distanceKm =
                                                        RadiusCalculate
                                                            .calculateDistance(
                                                      position.latitude,
                                                      position.longitude,
                                                      latitudePoint,
                                                      longitudePoint,
                                                    );

                                                    if (distanceKm >
                                                        radiusPoint) {
                                                      showCupertinoAlertDialog(
                                                          context,
                                                          'Anda diluar jangkauan absen');
                                                      return;
                                                    }

                                                    if (isCheckin) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Anda sudah checkin'),
                                                          backgroundColor:
                                                              AppColors.red,
                                                        ),
                                                      );
                                                    } else {
                                                      context.push(
                                                          const AttendanceCheckinPage());
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.all(10.0),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius:
                                                          BorderRadius.all(
                                                        Radius.circular(50.0),
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons
                                                          .assignment_turned_in,
                                                      size:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              12,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        SizedBox(height: size.height / 100),
                                        Text(
                                          "Datang",
                                          style: TextStyle(
                                            fontSize: size.width / 25,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        BlocBuilder<GetCompanyBloc,
                                            GetCompanyState>(
                                          builder: (context, state) {
                                            final latitudePoint =
                                                state.maybeWhen(
                                              orElse: () => 0.0,
                                              success: (data) =>
                                                  double.parse(data.latitude!),
                                            );
                                            final longitudePoint =
                                                state.maybeWhen(
                                              orElse: () => 0.0,
                                              success: (data) =>
                                                  double.parse(data.longitude!),
                                            );
                                            final radiusPoint = state.maybeWhen(
                                              orElse: () => 0.0,
                                              success: (data) =>
                                                  double.parse(data.radiusKm!),
                                            );

                                            return BlocBuilder<IsCheckedinBloc,
                                                IsCheckedinState>(
                                              builder:
                                                  (context, isCheckedinState) {
                                                final isCheckout =
                                                    isCheckedinState.maybeWhen(
                                                  orElse: () => false,
                                                  success: (data) =>
                                                      data.isCheckedout,
                                                );
                                                final isCheckIn =
                                                    isCheckedinState.maybeWhen(
                                                  orElse: () => false,
                                                  success: (data) =>
                                                      data.isCheckedin,
                                                );

                                                return GestureDetector(
                                                  onTap: () async {
                                                    // Ambil posisi saat ini
                                                    final position =
                                                        await Geolocator
                                                            .getCurrentPosition();

                                                    // Deteksi lokasi palsu
                                                    if (position.isMocked) {
                                                      showCupertinoAlertDialog(
                                                          context,
                                                          'Anda menggunakan lokasi palsu');
                                                      return;
                                                    }

                                                    // Hitung jarak
                                                    final distanceKm =
                                                        RadiusCalculate
                                                            .calculateDistance(
                                                      position.latitude,
                                                      position.longitude,
                                                      latitudePoint,
                                                      longitudePoint,
                                                    );

                                                    print(
                                                        'jarak radius:  $distanceKm');

                                                    // Cek apakah di luar radius
                                                    if (distanceKm >
                                                        radiusPoint) {
                                                      showCupertinoAlertDialog(
                                                          context,
                                                          'Anda diluar jangkauan absen');
                                                      return;
                                                    }

                                                    // Cek status check-in dan check-out
                                                    if (!isCheckIn) {
                                                      showCupertinoAlertDialog(
                                                          context,
                                                          'Anda belum checkin');
                                                    } else if (isCheckout) {
                                                      showCupertinoAlertDialog(
                                                          context,
                                                          'Anda sudah checkout');
                                                    } else {
                                                      Navigator.of(context)
                                                          .push(
                                                              MaterialPageRoute(
                                                        builder: (context) =>
                                                            const AttendanceCheckoutPage(),
                                                      ));
                                                    }
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10.0),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary,
                                                      borderRadius:
                                                          const BorderRadius
                                                              .all(
                                                        Radius.circular(50.0),
                                                      ),
                                                    ),
                                                    child: Icon(
                                                      Icons.logout,
                                                      size:
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              12,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                        ),
                                        SizedBox(height: size.height / 100),
                                        Text(
                                          "Pulang",
                                          style: TextStyle(
                                            fontSize: size.width / 25,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () {},
                                          child: Container(
                                            padding: EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.all(
                                                Radius.circular(50.0),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.document_scanner,
                                              size: size.width / 12,
                                              color: AppColors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: size.height / 100),
                                        Text(
                                          "Izin",
                                          style: TextStyle(
                                            fontSize: size.width / 25,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        //banner
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: CarouselSlider(
                              options: CarouselOptions(
                                enlargeCenterPage: true,
                                autoPlay: true,
                                aspectRatio: 4 / 1,
                                autoPlayInterval: Duration(seconds: 5),
                              ),
                              items: [
                                "assets/images/banner.png",
                                "assets/images/banner.png",
                                "assets/images/banner.png",
                              ].map((i) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      10.0), // Sesuaikan radius sesuai kebutuhan
                                  child: Image.asset(
                                    i,
                                    width: size.width,
                                    fit: BoxFit.fill,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Pengumuman",
                                    style: TextStyle(
                                      fontSize: size.width / 25,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      "Lihat Semua",
                                      style: TextStyle(
                                        fontSize: size.width / 25,
                                        color: AppColors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: size.height / 50),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 10.0, vertical: 13.0),
                                width: size.width,
                                decoration: BoxDecoration(
                                  color: AppColors.light,
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10.0),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 0,
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Jadwal Hari ini...",
                                          style: TextStyle(
                                            fontSize: size.width / 25,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          "1 Agustus 2024",
                                          style: TextStyle(
                                            fontSize: size.width / 30,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Jadwal Hari ini...",
                                          style: TextStyle(
                                            fontSize: size.width / 25,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        Text(
                                          "1 Agustus 2024",
                                          style: TextStyle(
                                            fontSize: size.width / 30,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.0, vertical: 13.0),
                    margin: EdgeInsets.only(top: size.height / 3.6),
                    width: size.width, // Lebar penuh
                    decoration: BoxDecoration(
                      color: AppColors.light,
                      borderRadius: BorderRadius.all(
                        Radius.circular(10.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2), // Warna shadow
                          spreadRadius: 0, // Radius sebaran shadow
                          blurRadius: 10, // Radius blur shadow
                          offset:
                              Offset(0, 5), // Offset shadow (geser ke bawah)
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Jadwal Hari ini",
                          style: TextStyle(
                            fontSize: size.width / 25,
                            color: AppColors.primary,
                          ),
                        ),
                        BlocBuilder<GetCompanyBloc, GetCompanyState>(
                          builder: (context, state) {
                            final timeIn = state.maybeWhen(
                              orElse: () => '00:00',
                              success: (data) => data.timeIn!,
                            );
                            final timeOut = state.maybeWhen(
                              orElse: () => '00:00',
                              success: (data) => data.timeOut!,
                            );
                            return Text(
                              '$timeIn WIB - $timeOut WIB',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: size.width / 20,
                                  color: AppColors.primary),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SingleChildScrollView(
//         child: Container(
//           padding: const EdgeInsets.all(16.0),
//           decoration: BoxDecoration(
//             image: DecorationImage(
//               image: Assets.images.bgHome.provider(),
//               alignment: Alignment.topCenter,
//             ),
//           ),
//           child: ListView(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             children: [
//               Row(
//                 children: [
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(50.0),
//                     // child: Image.network(
//                     //   'https://i.pinimg.com/originals/1b/14/53/1b14536a5f7e70664550df4ccaa5b231.jpg',
//                     //   width: 48.0,
//                     //   height: 48.0,
//                     //   fit: BoxFit.cover,
//                     // ),
//                   ),
//                   const SpaceWidth(12.0),
//                   Expanded(
//                     child: FutureBuilder(
//                       future: AuthLocalDatasource().getAuthData(),
//                       builder: (context, snapshot) {
//                         if (snapshot.connectionState ==
//                             ConnectionState.waiting) {
//                           return const Text('Loading...');
//                         } else {
//                           final user = snapshot.data?.user;
//                           return Text(
//                             'Hello, ${user?.name ?? '...'}',
//                             style: const TextStyle(
//                               fontSize: 18.0,
//                               color: AppColors.white,
//                             ),
//                             maxLines: 2,
//                           );
//                         }
//                       },
//                     ),
//                   ),
//                   IconButton(
//                     onPressed: () {},
//                     icon: Assets.icons.notificationRounded.svg(),
//                   ),
//                 ],
//               ),
//               const SpaceHeight(24.0),
//               Container(
//                 padding: const EdgeInsets.all(24.0),
//                 decoration: BoxDecoration(
//                   color: AppColors.white,
//                   borderRadius: BorderRadius.circular(20.0),
//                 ),
//                 child: Column(
//                   children: [
//                     const ClockWidget(), // Gunakan ClockWidget di sini
//                     const SpaceHeight(18.0),
//                     const Divider(),
//                     const SpaceHeight(30.0),
//                     Text(
//                       DateTime.now().toFormattedDate(),
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.grey,
//                       ),
//                     ),
//                     const SpaceHeight(6.0),
//                     Text(
//                       '${DateTime(2024, 3, 14, 9, 0).toFormattedTime()} - ${DateTime(2024, 3, 14, 15, 0).toFormattedTime()}',
//                       style: const TextStyle(
//                         fontWeight: FontWeight.w700,
//                         fontSize: 20.0,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SpaceHeight(80.0),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16.0),
//                 child: GridView(
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 2,
//                     crossAxisSpacing: 16.0,
//                     mainAxisSpacing: 16.0,
//                   ),
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   children: [
                    // BlocBuilder<GetCompanyBloc, GetCompanyState>(
                    //   builder: (context, state) {
                    //     final latitudePoint = state.maybeWhen(
                    //       orElse: () => 0.0,
                    //       success: (data) => double.parse(data.latitude!),
                    //     );
                    //     final longitudePoint = state.maybeWhen(
                    //       orElse: () => 0.0,
                    //       success: (data) => double.parse(data.longitude!),
                    //     );

                    //     final radiusPoint = state.maybeWhen(
                    //       orElse: () => 0.0,
                    //       success: (data) => double.parse(data.radiusKm!),
                    //     );
                    //     return BlocConsumer<IsCheckedinBloc, IsCheckedinState>(
                    //       listener: (context, state) {
                    //         //
                    //       },
                    //       builder: (context, state) {
                    //         final isCheckin = state.maybeWhen(
                    //           orElse: () => false,
                    //           success: (data) => data.isCheckedin,
                    //         );

                    //         return MenuButton(
                    //           label: 'Datang',
                    //           iconPath: Assets.icons.menu.datang.path,
                    //           onPressed: () async {
                    //             // Deteksi lokasi palsu

                    //             // masuk page checkin

                    //             final distanceKm =
                    //                 RadiusCalculate.calculateDistance(
                    //                     latitude ?? 0.0,
                    //                     longitude ?? 0.0,
                    //                     latitudePoint,
                    //                     longitudePoint);

                    //             final position =
                    //                 await Geolocator.getCurrentPosition();

                    //             if (position.isMocked) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content:
                    //                       Text('Anda menggunakan lokasi palsu'),
                    //                   backgroundColor: AppColors.red,
                    //                 ),
                    //               );
                    //               return;
                    //             }

                    //             if (distanceKm > radiusPoint) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content:
                    //                       Text('Anda diluar jangkauan absen'),
                    //                   backgroundColor: AppColors.red,
                    //                 ),
                    //               );
                    //               return;
                    //             }

                    //             if (isCheckin) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content: Text('Anda sudah checkin'),
                    //                   backgroundColor: AppColors.red,
                    //                 ),
                    //               );
                    //             } else {
                    //               context.push(const AttendanceCheckinPage());
                    //             }
                    //           },
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),
                    // BlocBuilder<GetCompanyBloc, GetCompanyState>(
                    //   builder: (context, state) {
                    //     final latitudePoint = state.maybeWhen(
                    //       orElse: () => 0.0,
                    //       success: (data) => double.parse(data.latitude!),
                    //     );
                    //     final longitudePoint = state.maybeWhen(
                    //       orElse: () => 0.0,
                    //       success: (data) => double.parse(data.longitude!),
                    //     );

                    //     final radiusPoint = state.maybeWhen(
                    //       orElse: () => 0.0,
                    //       success: (data) => double.parse(data.radiusKm!),
                    //     );
                    //     return BlocBuilder<IsCheckedinBloc, IsCheckedinState>(
                    //       builder: (context, state) {
                    //         final isCheckout = state.maybeWhen(
                    //           orElse: () => false,
                    //           success: (data) => data.isCheckedout,
                    //         );
                    //         final isCheckIn = state.maybeWhen(
                    //           orElse: () => false,
                    //           success: (data) => data.isCheckedin,
                    //         );
                    //         return MenuButton(
                    //           label: 'Pulang',
                    //           iconPath: Assets.icons.menu.pulang.path,
                    //           onPressed: () async {
                    //             final distanceKm =
                    //                 RadiusCalculate.calculateDistance(
                    //                     latitude ?? 0.0,
                    //                     longitude ?? 0.0,
                    //                     latitudePoint,
                    //                     longitudePoint);
                    //             final position =
                    //                 await Geolocator.getCurrentPosition();

                    //             if (position.isMocked) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content:
                    //                       Text('Anda menggunakan lokasi palsu'),
                    //                   backgroundColor: AppColors.red,
                    //                 ),
                    //               );
                    //               return;
                    //             }

                    //             print('jarak radius:  $distanceKm');

                    //             if (distanceKm > radiusPoint) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content:
                    //                       Text('Anda diluar jangkauan absen'),
                    //                   backgroundColor: AppColors.red,
                    //                 ),
                    //               );
                    //               return;
                    //             }
                    //             if (!isCheckIn) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content: Text('Anda belum checkin'),
                    //                   backgroundColor: AppColors.red,
                    //                 ),
                    //               );
                    //             } else if (isCheckout) {
                    //               ScaffoldMessenger.of(context).showSnackBar(
                    //                 const SnackBar(
                    //                   content: Text('Anda sudah checkout'),
                    //                   backgroundColor: AppColors.red,
                    //                 ),
                    //               );
                    //             } else {
                    //               context.push(const AttendanceCheckoutPage());
                    //             }
                    //           },
                    //         );
                    //       },
                    //     );
                    //   },
                    // ),
//                     MenuButton(
//                       label: 'Izin',
//                       iconPath: Assets.icons.menu.izin.path,
//                       onPressed: () {
//                         context.push(const PermissionPage());
//                       },
//                     ),
//                     MenuButton(
//                       label: 'Catatan',
//                       iconPath: Assets.icons.menu.catatan.path,
//                       onPressed: () {},
//                     ),
//                   ],
//                 ),
//               ),
//               const SpaceHeight(24.0),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
