import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart' as pkg_ffi;

class BassPlugin {
    final ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
      _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  BassPlugin(ffi.DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  BassPlugin.fromLookup(
      ffi.Pointer<T> Function<T extends ffi.NativeType>(String symbolName)
          lookup)
      : _lookup = lookup;

  int BassPlugin_version(
    ffi.Pointer<ffi.Pointer<BassPlugin_context>> ctx,
  ) {
    return _BassPlugin_version(
      ctx,
    );
  }
  late final _bassplugin_versionPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Pointer<BassPlugin_context>>)>>('BASS_GetVersion');  
  late final _BassPlugin_version = _bassplugin_versionPtr
      .asFunction<int Function(ffi.Pointer<ffi.Pointer<BassPlugin_context>>)>();

  bool BassPlugin_init(
    ffi.Pointer<ffi.Pointer<BassPlugin_config>> config,
  ) {
    return _BassPlugin_init(
      -1,48000, 0,0, config
    );
  }
  late final _bassplugin_initPtr = _lookup<
      ffi.NativeFunction<
          ffi.Bool Function(
            ffi.Int,ffi.Int, ffi.Int,ffi.Int, ffi.Pointer<ffi.Pointer<BassPlugin_config>>)>>('BASS_Init');  
  late final _BassPlugin_init = _bassplugin_initPtr
      .asFunction<bool Function(int,int, int,int, ffi.Pointer<ffi.Pointer<BassPlugin_config>>)>();

  int BassPlugin_channelGetData(
    ffi.Pointer<ffi.Pointer<ffi.Pointer<BassPlugin_sampleBuffer>>> sampleBuffer,
  ) {
    return _BassPlugin_channelGetData(
      0, sampleBuffer,  2 * 48000 * 8
    );
  }
  late final _bassplugin_channelGetDataPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
            ffi.Int, ffi.Pointer<ffi.Pointer<ffi.Pointer<BassPlugin_sampleBuffer>>>, ffi.Int)>>('BASS_ChannelGetData');  
  late final _BassPlugin_channelGetData = _bassplugin_channelGetDataPtr
      .asFunction<int Function(int, ffi.Pointer<ffi.Pointer<ffi.Pointer<BassPlugin_sampleBuffer>>>, int)>();



  int BassPlugin_error(
    ffi.Pointer<ffi.Pointer<BassPlugin_context>> ctx,
  ) {
    return _BassPlugin_error(
      ctx,
    );
  }
  late final _bassplugin_errorPtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Pointer<BassPlugin_context>>)>>('BASS_ErrorGetCode');  
  late final _BassPlugin_error = _bassplugin_errorPtr
      .asFunction<int Function(ffi.Pointer<ffi.Pointer<BassPlugin_context>>)>();

  int BassPlugin_streamCreate(
    ffi.Pointer<ffi.Pointer<BassPlugin_context>> ctx,
  ) {
    return _BassPlugin_streamCreate(
      ctx,
    );
  }
  late final _bassplugin_streamCreatePtr = _lookup<
      ffi.NativeFunction<
          ffi.Int Function(
              ffi.Pointer<ffi.Pointer<BassPlugin_context>>)>>('BASS_StreamCreate');  
  late final _BassPlugin_streamCreate = _bassplugin_streamCreatePtr
      .asFunction<int Function(ffi.Pointer<ffi.Pointer<BassPlugin_context>>)>();

}

class BassPlugin_context extends ffi.Opaque {}
class BassPlugin_config extends ffi.Opaque {}
class BassPlugin_sampleBuffer extends ffi.Opaque {}
class BassPlugin_HSTREAM extends ffi.Opaque {}
