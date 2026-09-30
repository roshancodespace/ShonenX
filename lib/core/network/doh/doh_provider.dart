enum DohProvider {
  cloudflare(
    'Cloudflare (Default)',
    '1.1.1.1 (Fast, privacy-focused)',
    primaryUrl: 'https://1.1.1.1/dns-query',
    secondaryUrl: 'https://1.0.0.1/dns-query',
    hostHeader: 'cloudflare-dns.com',
    acceptHeader: 'application/dns-json',
    bootstrapIps: ['1.1.1.1', '1.0.0.1'],
  ),
  google(
    'Google',
    '8.8.8.8 (Global & reliable)',
    primaryUrl: 'https://8.8.8.8/resolve',
    secondaryUrl: 'https://8.8.4.4/resolve',
    hostHeader: 'dns.google',
    acceptHeader: 'application/json',
    bootstrapIps: ['8.8.8.8', '8.8.4.4'],
  ),
  system(
    'System (Disabled)',
    'Use device default DNS resolver',
    primaryUrl: '',
    secondaryUrl: '',
    hostHeader: '',
    acceptHeader: '',
    bootstrapIps: [],
  );

  final String title;
  final String description;
  final String primaryUrl;
  final String secondaryUrl;
  final String hostHeader;
  final String acceptHeader;
  final List<String> bootstrapIps;

  const DohProvider(
    this.title,
    this.description, {
    required this.primaryUrl,
    required this.secondaryUrl,
    required this.hostHeader,
    required this.acceptHeader,
    required this.bootstrapIps,
  });

  bool get isDoh => this != DohProvider.system;
}
