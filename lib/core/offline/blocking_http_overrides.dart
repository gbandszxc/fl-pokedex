import 'dart:io';

/// 运行时 HTTP 请求被离线守卫拦截时抛出（PRODUCT.md 硬性契约：0 网络请求）。
class OfflineRequestBlocked implements Exception {
  const OfflineRequestBlocked(this.url);

  /// 被拦截的请求 URL（原始字符串）。
  final String url;

  @override
  String toString() =>
      'OfflineRequestBlocked: 离线守卫拦截了 HTTP 请求 → $url。'
      '琥珀图鉴运行时禁止任何网络请求，请改用本地数据源（assets/database）。';
}

/// main() 中无条件 `HttpOverrides.global = BlockingHttpOverrides()`（architecture.md §8）。
///
/// 经此 override 创建的所有 [HttpClient] 在发起请求（open/openUrl/get/...）
/// 时直接抛 [OfflineRequestBlocked]，集成测试据此验收 0 请求。
class BlockingHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // super.createHttpClient 直接构造 dart:io 内部实现，不经过工厂，
    // 不会递归回到本 override。
    return _BlockingHttpClient(super.createHttpClient(context));
  }
}

/// 代理客户端：所有发起请求的入口一律抛出；
/// 回调/生命周期配置成员原样透传内部客户端（Dart 3.13 HttpClient 接口）。
class _BlockingHttpClient implements HttpClient {
  _BlockingHttpClient(this._inner);

  final HttpClient _inner;

  Never _blocked(String method, Object url) =>
      throw OfflineRequestBlocked('$method $url');

  // ---- 请求入口：全部拦截 ----

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      _blocked(method, url);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) =>
      _blocked(method, Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> getUrl(Uri url) => _blocked('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) => _blocked('POST', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) => _blocked('PUT', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) => _blocked('DELETE', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) => _blocked('HEAD', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) => _blocked('PATCH', url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _blocked('GET', Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _blocked('POST', Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _blocked('PUT', Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _blocked('DELETE', Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _blocked('HEAD', Uri(host: host, port: port, path: path));

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _blocked('PATCH', Uri(host: host, port: port, path: path));

  // ---- 回调与生命周期配置：透传（不再能发起请求） ----

  @override
  Duration get idleTimeout => _inner.idleTimeout;

  @override
  set idleTimeout(Duration value) => _inner.idleTimeout = value;

  @override
  Duration? get connectionTimeout => _inner.connectionTimeout;

  @override
  set connectionTimeout(Duration? value) => _inner.connectionTimeout = value;

  @override
  int? get maxConnectionsPerHost => _inner.maxConnectionsPerHost;

  @override
  set maxConnectionsPerHost(int? value) => _inner.maxConnectionsPerHost = value;

  @override
  bool get autoUncompress => _inner.autoUncompress;

  @override
  set autoUncompress(bool value) => _inner.autoUncompress = value;

  @override
  String? get userAgent => _inner.userAgent;

  @override
  set userAgent(String? value) => _inner.userAgent = value;

  @override
  set authenticate(
    Future<bool> Function(Uri url, String scheme, String? realm)? f,
  ) =>
      _inner.authenticate = f;

  @override
  set authenticateProxy(
    Future<bool> Function(String host, int port, String scheme, String? realm)?
    f,
  ) =>
      _inner.authenticateProxy = f;

  @override
  set badCertificateCallback(
    bool Function(X509Certificate cert, String host, int port)? callback,
  ) =>
      _inner.badCertificateCallback = callback;

  @override
  set keyLog(Function(String line)? callback) => _inner.keyLog = callback;

  @override
  set findProxy(String Function(Uri url)? f) => _inner.findProxy = f;

  @override
  set connectionFactory(
    Future<ConnectionTask<Socket>> Function(
      Uri url,
      String? proxyHost,
      int? proxyPort,
    )?
    f,
  ) =>
      _inner.connectionFactory = f;

  @override
  void addCredentials(
    Uri url,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addCredentials(url, realm, credentials);

  @override
  void addProxyCredentials(
    String host,
    int port,
    String realm,
    HttpClientCredentials credentials,
  ) =>
      _inner.addProxyCredentials(host, port, realm, credentials);

  @override
  void close({bool force = false}) => _inner.close(force: force);
}
