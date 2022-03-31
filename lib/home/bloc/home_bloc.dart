import 'dart:developer';
import 'dart:ffi';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_assistant_client/repository/common_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../model/mobile_info.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final CommonRepository _commonRepository;

  HomeBloc({required CommonRepository commonRepository})
      : _commonRepository = commonRepository,
        super(HomeState(tab: HomeTab.image)) {
    on<HomeTabChanged>(_onHomeTabChanged);
    on<HomeSubscriptionRequested>(_onSubscriptionRequested);
  }

  void _onHomeTabChanged(HomeTabChanged event, Emitter<HomeState> emit) {
    emit(state.copyWith(tab: event.tab));
  }

  void _onSubscriptionRequested(
      HomeSubscriptionRequested event, Emitter<HomeState> emit) async {
    MobileInfo mobileInfo = await _commonRepository.getMobileInfo();

    String? appVersion = null;

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (e) {
      log("HomeBloc: get the app version failure!");
    }
    emit(state.copyWith(mobileInfo: mobileInfo, version: appVersion));
  }
}
