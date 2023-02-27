import 'package:another_flushbar/flushbar_helper.dart';
import 'package:hmi_networking/hmi_networking.dart';
import 'package:flutter/material.dart';
import 'package:hmi_core/hmi_core.dart';
import 'package:hmi_core/hmi_core_app_settings.dart';
import 'package:hmi_widgets/src/edit_field/network_field_authenticate.dart';

///
/// Gets and shows the value of type [T] from the DataServer.
/// If the value edited by user, sends new value to the DataServer.
/// The value can be edited onle if current user present in the list of allwed.
/// Shows progress indicator until network operation complited.
class NetworkEditField<T> extends StatefulWidget {
  final DsClient? _dsClient;
  final DsPointName? _writeTagName;
  final String? _responseTagName;
  final AppUserStacked? _users;
  final List<String> _allowedGroups;
  final TextInputType? _keyboardType;
  final int _fractionDigits;
  final String? _labelText;
  final String? _unitText;
  final double _width;
  final bool _showApplyButton;
  final Duration? _flushBarDuration;
  final int _responseTimeout;
  ///
  /// - [writeTagName] - the name of DataServer tag to send value
  /// - [responseTagName] - the name of DataServer tag to get response if value written
  /// - [users] - current stack of authenticated users
  /// tried to edit the value but not in list of allowed
  /// - [allowedGroups] - list of user group names allowed to edit this field
  /// - [responseTimeout] - timeout in seconds to wait server response
  const NetworkEditField({
    Key? key,
    List<String> allowedGroups = const [],
    AppUserStacked? users,
    DsClient? dsClient,
    DsPointName? writeTagName,
    String? responseTagName,
    TextInputType? keyboardType,
    int fractionDigits = 0,
    String? labelText,
    String? unitText,
    double width = 230.0,
    showApplyButton = false,
    Duration? flushBarDuration,
    int responseTimeout = 5,
  }) : 
    _allowedGroups = allowedGroups,
    _users = users,
    _dsClient = dsClient,
    _writeTagName = writeTagName,
    _responseTagName = responseTagName,
    _keyboardType = keyboardType,
    _fractionDigits = fractionDigits,
    _labelText = labelText,
    _unitText = unitText,
    _width = width,
    _showApplyButton = showApplyButton,
    _flushBarDuration = flushBarDuration,
    _responseTimeout = responseTimeout,
    super(key: key);
  //
  @override
  // ignore: no_logic_in_create_state
  State<NetworkEditField<T>> createState() => _NetworkEditFieldState<T>(
    users: _users,
    dsClient: _dsClient,
    writeTagName: _writeTagName,
    responseTagName: _responseTagName,
    allowedGroups: _allowedGroups,
    keyboardType: _keyboardType,
    fractionDigits: _fractionDigits,
    labelText: _labelText,
    unitText: _unitText,
    width: _width,
    showApplyButton: _showApplyButton,
    flushBarDuration: _flushBarDuration,
    responseTimeout: _responseTimeout
  );
}

///
class _NetworkEditFieldState<T> extends State<NetworkEditField<T>> {
  final _log = Log('${_NetworkEditFieldState<T>}')..level = LogLevel.debug;
  final _state = NetworkOperationState(isLoading: true);
  final TextEditingController _editingController = TextEditingController();
  final List<String> _allowedGroups;
  late AppUserStacked? _users;
  final DsClient? _dsClient;
  final DsPointName? _writeTagName;
  final String? _responseTagName;
  final TextInputType? _keyboardType;
  final int _fractionDigits;
  final String? _labelText;
  final String? _unitText;
  final double _width;
  final bool _showApplyButton;
  final Duration? _flushBarDuration;
  final int _responseTimeout;
  // bool _accessAllowed = false;
  String _initValue = '';
  ///
  _NetworkEditFieldState({
    required List<String> allowedGroups,
    required AppUserStacked? users,
    required DsClient? dsClient,
    required DsPointName? writeTagName,
    required String? responseTagName,
    required TextInputType? keyboardType,
    required int fractionDigits,
    required String? labelText,
    required String? unitText,
    required double width,
    required bool showApplyButton,
    required int responseTimeout,
    Duration? flushBarDuration,
  }) : 
    assert(T == int || T == double, 'Generic <T> must be int or double.'),
    _allowedGroups = allowedGroups,
    _users = users,
    _dsClient = dsClient,
    _writeTagName = writeTagName,
    _responseTagName = responseTagName,
    _keyboardType = keyboardType,
    _fractionDigits = fractionDigits,
    _labelText = labelText,
    _unitText = unitText,
    _width = width,
    _showApplyButton = showApplyButton,
    _flushBarDuration = flushBarDuration,
    _responseTimeout = responseTimeout,
    super();
  //
  @override
  void initState() {
    super.initState();
    final dsClient = _dsClient;
    final writeTagName = _writeTagName;
    final responseTagName = _responseTagName != null
        ? _responseTagName
        : writeTagName != null
            ? writeTagName.name
            : writeTagName != null
                ? writeTagName.name
                : null;
    if (responseTagName != null) {
      dsClient?.stream<T>(responseTagName).listen((event) {
        _log.debug('[$runtimeType.didChangeDependencies] event: $event');
        _log.debug('[$runtimeType.didChangeDependencies] event.value: ${event.value}');
        _initValue = (event.value as num).toStringAsFixed(_fractionDigits);
        if (!_state.isEditing) {
          _log.debug('[$runtimeType.didChangeDependencies] _initValue: $_initValue');
          _editingController.text = _initValue;
        }
        if (mounted) {
          setState(() {
            _state.setLoaded();
          });
        }
      });
    }
  }
  //
  @override
  Widget build(BuildContext context) {
    _log.debug('[.build] _users', _users?.toList());
    return SizedBox(
      width: _width,
      child: RepaintBoundary(
        child: TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) => _valueValidator(value),
          controller: _editingController,
          keyboardType: _keyboardType,
          textAlign: TextAlign.end,
          decoration: InputDecoration(
            suffixText: _unitText,
            prefixStyle: Theme.of(context).textTheme.bodyMedium,
            label: Text(
              '$_labelText',
              softWrap: false,
              overflow: TextOverflow.fade,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontSize: Theme.of(context).textTheme.labelLarge!.fontSize,
                  ),
            ),
            alignLabelWithHint: true,
            errorMaxLines: 3,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (_showApplyButton)
                  IconButton(
                    onPressed: () => _onEditingComplete(), 
                    icon: Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
                  ),
                _buildSufixIcon(),
              ],
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.background,
          ),
          onChanged: (newValue) async {
            _log.debug('[.build.onChanged] newValue: $newValue');
            if (_state.isAuthenticating) {
              _editingController.text = _initValue;
            } else {
              if (newValue != _initValue) {
                await _requestAccess().then((_) {
                  if (_state.isAuthenticeted) {
                    if (!_state.isChanged) {
                      _state.setEditing();
                      _state.setChanged();
                    }
                    if (mounted) setState(() {;});
                  } else {
                    _editingController.text = _initValue;
                  }
                });
              } else {
                if (_state.isChanged) {
                  // _state.setChanged();
                  if (mounted) setState(() {
                    _state.setLoaded();
                  });
                }
              }
            }
          },
          onEditingComplete: () => _onEditingComplete(),
          onFieldSubmitted: (value) {
            _log.debug('[.build] onFieldSubmitted');
          },
          onSaved: (newValue) {
            _log.debug('[.build] onSaved');
          },
        ),
      ),
    );
  }
  ///
  /// validating if the value can be parsed in to T (int / double)
  String? _valueValidator(value) {
    final result = _parseValue(value, fractionDigits: _fractionDigits);
    return result.hasError ? const Localized('Invalid date value').v : null;
  }
  ///
  void _onEditingComplete() {
    _log.debug('[._onEditingComplete]');
    _parseValue(_editingController.text, fractionDigits: _fractionDigits).fold(
      onData: (numValue) {
        if ('${numValue}' != _initValue) {
          _log.debug('[.build._onEditingComplete] new numValue: ${numValue}\t_initValue: $_initValue');
          _sendValue(_dsClient, _writeTagName, _responseTagName, numValue);
        }
      }, 
      onError: (failure) {
        _log.debug('[.build._onEditingComplete] error: ${failure.message}');
      },
    );
  }
  ///
  /// Parses string into T (int / double)
  Result<T> _parseValue(String value, {int fractionDigits = 0}) {
    if (T == int) {
      return _textToInt(value);
    } else if (T == double) {
      return _textToFixedDouble(value, fractionDigits);
    } else {
      return Result<T>(
        error: Failure.convertion(
          message: 'Ошибка в методе $runtimeType._textToFixedDouble: value "${_editingController.text}" can`t be converted', 
          stackTrace: StackTrace.current
        ),
      );
    }
  }
  ///
  Result<T> _textToInt(String value) {
    final intValue = int.tryParse(value);
    return intValue != null 
      ? Result<T>(data: intValue as T) 
      : Result<T>(
        error: Failure.convertion(
          message: 'Ошибка в методе $runtimeType._textToInt: value "$value" can`t be converted into int', 
          stackTrace: StackTrace.current),
        );
  }
  ///
  Result<T> _textToFixedDouble(String value, int fractionDigits) {
    final doubleValue = double.tryParse(value);
    if (doubleValue != null) {
      return Result<T>(data: double.parse(doubleValue.toStringAsFixed(fractionDigits)) as T);
    } else {
      return Result<T>(
        error: Failure.convertion(
          message: 'Ошибка в методе $runtimeType._textToFixedDouble: value "$value" can`t be converted into double', 
          stackTrace: StackTrace.current,
        ),
      );
    }
  }
  ///
  void _sendValue(
    DsClient? dsClient, 
    DsPointName? writeTagName,
    String? responseTagName, 
    T? newValue,
  ) {
    _log.debug('[._sendValue] newValue: ', newValue);
    final value = newValue;
    if (dsClient != null && writeTagName != null && value != null) {
      setState(() {
        _state.setSaving();
      });
      DsSend<T>(
        dsClient: dsClient,
        pointName: writeTagName,
        response: responseTagName,
        responseTimeout: _responseTimeout,
      ).exec(value).then((responseValue) {
        setState(() {
          _state.setSaved();
          if (responseValue.hasError) {
            _state.setChanged();
          }
        });
      });
    }
  }
  ///
  Widget _buildSufixIcon() {
    if (_state.isLoading || _state.isSaving) {
      return _buildProgressIndicator();
    }
    if (_state.isChanged) {
      return const Icon(Icons.info_outline);
    }
    if (_state.isSaved) {
      return Icon(Icons.check, color: Theme.of(context).primaryColor);
    }
    return Icon(null);
  }
  ///
  Widget _buildProgressIndicator() {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 3,
      ),
    );
  }
  /// Проверяет наличие доступа у текущего пользователя
  /// на редактирования данного поля
  Future<void> _requestAccess() async {
    _state.setAuthenticating();
    if (_allowedGroups.isEmpty) {
      _state.setAuthenticated();
      // _accessAllowed = true;
      return;
    }
    final users = _users;
    if (users != null) {
      _log.debug('[._requestAccess] users:', users.toList());
      final user = users.peek;
      _log.debug('[._requestAccess] user:', user);
      _log.debug('[._requestAccess] _user.group:', user.userGroup().value);
      if (user.exists()) {
        if (_allowedGroups.contains(user.userGroup().value)) {
          _state.setAuthenticated();
          // _accessAllowed = true;
          return;
        }
      }
      networkFieldAuthenticate(
        context, 
        users, 
      ).then((AuthResult authResult) {
        if (authResult.authenticated) {
          setState(() {
            _state.setAuthenticated();
            // _accessAllowed = true;
            return;
          });
        }
      });
    }
    FlushbarHelper.createError(
      duration: _flushBarDuration ?? Duration(
        milliseconds: const Setting('flushBarDurationMedium').toInt,
      ),
      message: const Localized('Editing is not permitted for current user').v,
    ).show(context);
    _state.setAuthenticated(authenticated: false);
    // _accessAllowed = false;
  }
}
