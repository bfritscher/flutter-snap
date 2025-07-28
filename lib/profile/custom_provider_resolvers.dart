import 'package:firebase_ui_auth/firebase_ui_auth.dart' show providerIcon, AuthProvider;
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../oidc_eduid.dart';

Widget customProviderIcon(BuildContext context, AuthProvider provider) {
  try {
    return providerIcon(context, provider);
  } catch (e) {
    return SvgPicture.string(
      dartIconSvgLight,
      width: 24,
      height: 24,
    );
  }
}
