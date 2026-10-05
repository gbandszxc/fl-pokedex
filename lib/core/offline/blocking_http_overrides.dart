import 'dart:io';

/// 运行时 HTTP 请求被离线守卫拦截时抛出（PRODUCT.md 硬性契约：图鉴数据 0 网络请求）。
class OfflineRequestBlocked implements Exception {
  const OfflineRequestBlocked(this.url);

  /// 被拦截的请求 URL（原始字符串）。
  final String url;

  @override
  String toString() =>
      'OfflineRequestBlocked: 离线守卫拦截了 HTTP 请求 → $url。'
      'Fl-PokeDex 只有更新通道（检查更新/下载安装包）可联网，其余一律请改用本地数据源'
      '（assets/database）。';
}

/// 更新通道白名单主机（architecture.md §8）：GitHub 发布网页与资产下载域。
///
/// 检查更新读 `github.com/<repo>/releases/**` 网页，下载安装包经
/// `github.com/<repo>/releases/download/**` 302 到
/// `release-assets.githubusercontent.com`（历史版本曾用
/// `objects.githubusercontent.com` / `github-releases.githubusercontent.com`）。
const Set<String> kUpdateChannelAllowedHosts = {
  'github.com',
  'release-assets.githubusercontent.com',
  'objects.githubusercontent.com',
  'github-releases.githubusercontent.com',
};

/// 该 URI 是否属于更新通道（唯一放行的联网用途，且必须 https）。
bool isUpdateChannelUriAllowed(Uri uri) =>
    uri.scheme == 'https' && kUpdateChannelAllowedHosts.contains(uri.host);

/// main() 中无条件 `HttpOverrides.global = BlockingHttpOverrides()`（architecture.md §8）。
///
/// 经此 override 创建的所有 [HttpClient] 只在请求更新通道白名单主机时透传给
/// 真实客户端，其余一律抛 [OfflineRequestBlocked]——任何非更新功能试图联网都会
/// 立刻暴露而非静默请求。
class BlockingHttpOverrides extends HttpOverrides {
  BlockingHttpOverrides({this.allowedHosts = kUpdateChannelAllowedHosts});

  /// 放行主机集合（测试可注入空集合验证全量拦截）。
  final Set<String> allowedHosts;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    // super.createHttpClient 直接构造 dart:io 内部实现，不经过工厂，
    // 不会递归回到本 override。
    return _BlockingHttpClient(super.createHttpClient(context), allowedHosts);
  }
}

/// 代理客户端：更新通道白名单主机透传给内部客户端，其余请求入口一律抛出；
/// 回调/生命周期配置成员原样透传内部客户端（Dart 3.13 HttpClient 接口）。
class _BlockingHttpClient implements HttpClient {
  _BlockingHttpClient(this._inner, this._allowedHosts);

  final HttpClient _inner;

  final Set<String> _allowedHosts;

  Never _blocked(String method, Object url) =>
      throw OfflineRequestBlocked('$method $url');

  bool _allowsUri(Uri url) =>
      url.scheme == 'https' && _allowedHosts.contains(url.host);

  /// 仅接受 https + 白名单主机的 (host, port, path) 旧式入口。
  bool _allowsHostPort(String host, int port) =>
      port == 443 && _allowedHosts.contains(host);

  // ---- 请求入口：白名单透传，其余全部拦截 ----

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) => _allowsUri(url)
      ? _inner.openUrl(method, url)
      : _blocked(method, url);

  @override
  Future<HttpClientRequest> open(
    String method,
    String host,
    int port,
    String path,
  ) => _allowsHostPort(host, port)
      ? _inner.open(method, host, port, path)
      : _blocked(method, Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      _allowsUri(url) ? _inner.getUrl(url) : _blocked('GET', url);

  @override
  Future<HttpClientRequest> postUrl(Uri url) =>
      _allowsUri(url) ? _inner.postUrl(url) : _blocked('POST', url);

  @override
  Future<HttpClientRequest> putUrl(Uri url) =>
      _allowsUri(url) ? _inner.putUrl(url) : _blocked('PUT', url);

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) =>
      _allowsUri(url) ? _inner.deleteUrl(url) : _blocked('DELETE', url);

  @override
  Future<HttpClientRequest> headUrl(Uri url) =>
      _allowsUri(url) ? _inner.headUrl(url) : _blocked('HEAD', url);

  @override
  Future<HttpClientRequest> patchUrl(Uri url) =>
      _allowsUri(url) ? _inner.patchUrl(url) : _blocked('PATCH', url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) =>
      _allowsHostPort(host, port)
      ? _inner.get(host, port, path)
      : _blocked('GET', Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> post(String host, int port, String path) =>
      _allowsHostPort(host, port)
      ? _inner.post(host, port, path)
      : _blocked('POST', Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> put(String host, int port, String path) =>
      _allowsHostPort(host, port)
      ? _inner.put(host, port, path)
      : _blocked('PUT', Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) =>
      _allowsHostPort(host, port)
      ? _inner.delete(host, port, path)
      : _blocked('DELETE', Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> head(String host, int port, String path) =>
      _allowsHostPort(host, port)
      ? _inner.head(host, port, path)
      : _blocked('HEAD', Uri(host: host, port: port, path: path).toString());

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) =>
      _allowsHostPort(host, port)
      ? _inner.patch(host, port, path)
      : _blocked('PATCH', Uri(host: host, port: port, path: path).toString());

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
