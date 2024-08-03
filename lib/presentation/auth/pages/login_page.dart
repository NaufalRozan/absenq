import 'package:absenq/presentation/auth/bloc/login/login_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/core.dart';
import '../../../data/datasources/auth_local_datasource.dart';
import '../../home/pages/main_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final TextEditingController emailController;
  late final TextEditingController passwordController;
  bool isShowPassword = false;

  @override
  void initState() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.light,
      body: Stack(
        children: [
          Image.asset(
            Assets.images.bgLogin.path,
            width: size.width,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 50),
                    //link to the image
                    Image.asset(
                      'assets/gif/attendance_icon.gif',
                      width: size.width,
                      height: size.height / 3.5,
                    ),
                    Image.asset(
                      Assets.images.logoWhite.path,
                      width: size.width,
                      height: 80,
                    ),
                  ],
                ),
                const Spacer(),
                const Spacer(),
                Padding(
                  padding: EdgeInsets.symmetric( horizontal: 40),
                  child: Column(
                    children: [
                      CustomTextField(
                        controller: emailController,
                        label: 'Email Address',
                        showLabel: false,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            Assets.icons.email.path,
                            height: 20,
                            width: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomTextField(
                        controller: passwordController,
                        label: 'Password',
                        showLabel: false,
                        obscureText: !isShowPassword,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: SvgPicture.asset(
                            Assets.icons.password.path,
                            height: 20,
                            width: 20,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            isShowPassword
                            
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.primary,
                            
                          ),
                          onPressed: () {
                            setState(() {
                              isShowPassword = !isShowPassword;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      BlocListener<LoginBloc, LoginState>(
                        listener: (context, state) {
                          state.maybeWhen(
                            orElse: () {},
                            success: (data) {
                              AuthLocalDatasource().saveAuthData(data);
                              context.pushReplacement(const MainPage());
                            },
                            error: (message) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                  backgroundColor: AppColors.red,
                                ),
                              );
                            },
                          );
                        },
                        child: BlocBuilder<LoginBloc, LoginState>(
                          builder: (context, state) {
                            return state.maybeWhen(
                              orElse: () {
                                return Button.filled(
                                  onPressed: () {
                                    context.read<LoginBloc>().add(
                                          LoginEvent.login(
                                            emailController.text,
                                            passwordController.text,
                                          ),
                                        );
                                  },
                                  label: 'Login',
                                );
                              },
                              loading: () {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
