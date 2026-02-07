class Server {
  final String name;
  final String uuid;
  final String? ip;
  final bool hasVless;
  final bool hasSsh;
  final bool hasHysteria2;
  final String status;
  final String? vlessLink;
  final String? sshLink;
  final String? hysteria2Link;

  Server({
    required this.name,
    required this.uuid,
    this.ip,
    required this.hasVless,
    required this.hasSsh,
    required this.hasHysteria2,
    required this.status,
    this.vlessLink,
    this.sshLink,
    this.hysteria2Link,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      name: json['name'],
      uuid: json['uuid'],
      ip: json['ip'],
      hasVless: json['has_vless'] ?? false,
      hasSsh: json['has_ssh'] ?? false,
      hasHysteria2: json['has_hysteria2'] ?? false,
      status: json['status'] ?? 'subscribe',
      vlessLink: json['vless_link'],
      sshLink: json['ssh_link'],
      hysteria2Link: json['hysteria2_link'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'uuid': uuid,
        'ip': ip,
        'has_vless': hasVless,
        'has_ssh': hasSsh,
        'has_hysteria2': hasHysteria2,
        'status': status,
        'vless_link': vlessLink,
        'ssh_link': sshLink,
        'hysteria2_link': hysteria2Link,
      };
}

class Country {
  final String name;
  final String code;
  final List<Server> servers;

  Country({required this.name, required this.code, required this.servers});

  factory Country.fromJson(Map<String, dynamic> json, Map<String, String> countryCodes) {
    var serverList = json['servers'] as List;
    List<Server> servers = serverList.map((i) => Server.fromJson(i)).toList();
    return Country(
      name: json['name'],
      code: countryCodes[json['name']] ?? '',
      servers: servers,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        'servers': servers.map((s) => s.toJson()).toList(),
      };

  factory Country.fromCacheJson(Map<String, dynamic> json) {
    var serverList = json['servers'] as List;
    List<Server> servers = serverList.map((i) => Server.fromJson(i)).toList();
    return Country(
      name: json['name'],
      code: json['code'] ?? '',
      servers: servers,
    );
  }
}