require 'yaml'

ROOT = File.expand_path('..', __dir__)
MAIN = '🚀 手选主流'.freeze
US = '🇺🇸 美国-3'.freeze
INTERCOM = %w[intercom.com intercom.io intercomcdn.com intercom-chat.com intercom-sheets.com].freeze
OVERSEAS = %w[https://cloudflare-dns.com/dns-query https://dns.google/dns-query].freeze
DOMESTIC = %w[https://dns.alidns.com/dns-query https://doh.pub/dns-query].freeze
APPLE_DNS = %w[apple-relay.cloudflare.com apple-relay.fastly-edge.com cp4.cloudflare.com
               apple-relay.apple.com guzzoni.apple.com smoot.apple.com search.smoot.apple.com
               mask.icloud.com mask-h2.icloud.com mask-api.icloud.com].freeze

def check(condition, message)
  abort "FAIL #{message}" unless condition
end

def yaml(path)
  data = File.read(path)
  Psych.parse_stream(data).each do |node|
    next unless node.is_a?(Psych::Nodes::Mapping)

    keys = node.children.each_slice(2).map(&:first).grep(Psych::Nodes::Scalar).map(&:value)
    check(keys.uniq == keys, "#{File.basename(path)} duplicate mapping key at line #{node.start_line + 1}")
  end
  YAML.safe_load(data, aliases: true)
end

def visit(name, groups, active, done)
  return if done[name]

  check(!active[name], "proxy group cycle at #{name}")
  active[name] = true
  groups.fetch(name).fetch('proxies', []).each do |ref|
    visit(ref, groups, active, done) if groups.key?(ref)
  end
  active.delete(name)
  done[name] = true
end

def domain_match?(rule, host)
  kind, value = rule.split(',', 3)
  case kind
  when 'DOMAIN' then host == value
  when 'DOMAIN-SUFFIX' then host == value || host.end_with?(".#{value}")
  when 'DOMAIN-KEYWORD' then host.include?(value)
  end
end

def classify(rules, host, providers, geosite)
  rules.each do |rule|
    kind, value, target = rule.split(',')
    case kind
    when 'MATCH' then return [value, rule]
    when 'GEOSITE' then return [target, rule] if geosite.fetch(value, []).include?(host)
    when 'RULE-SET'
      return [target, rule] if providers.fetch(value, []).any? { |entry| domain_match?(entry, host) }
    else
      return [target, rule] if domain_match?(rule, host)
    end
  end
end

puts "Ruby #{RUBY_VERSION} / Psych #{Psych::VERSION}"
configs = %w[clash.yaml stash.yaml].map { |file| yaml(File.join(ROOT, file)) }
providers = { 'AgAI' => 'AI.yaml', 'Finance' => 'Finance.yaml', 'AgPrivate' => 'Private_DIRECT.yaml' }
providers.transform_values! do |file|
  payload = yaml(File.join(ROOT, file)).fetch('payload')
  check(payload.any? && payload.all? { |entry| entry.is_a?(String) }, "#{file} payload")
  puts "#{file} #{payload.size} entries"
  payload
end
# Use the downloaded list when supplied. The default is a one-entry fixture.
ad_source = ARGV.first
providers['AdvertisingLite'] = ad_source ? yaml(ad_source).fetch('payload') : ['DOMAIN-KEYWORD,adservice']
puts "AdvertisingLite: #{ad_source ? 'supplied snapshot' : 'one-entry fixture'}"
# Other remote providers have no entries in this model. The cn entry is a fixture.
geosite = { 'cn' => ['www.baidu.com'] }
puts 'GEOSITE cn: www.baidu.com fixture'

check(configs[0]['rules'] == configs[1]['rules'], 'main rule order differs')
check(configs[0]['proxy-groups'].map { |g| g['name'] } == configs[1]['proxy-groups'].map { |g| g['name'] }, 'group names differ')
check(configs[0]['rule-providers'].keys == configs[1]['rule-providers'].keys, 'provider names differ')
configs.each_with_index do |config, index|
  rules = config.fetch('rules')
  group_list = config.fetch('proxy-groups')
  groups = group_list.to_h { |group| [group.fetch('name'), group] }
  nodes = config.fetch('proxies')
  names = nodes.map { |node| node.fetch('name') }
  builtin = %w[DIRECT REJECT REJECT-DROP PASS COMPATIBLE GLOBAL]
  known = names + groups.keys + builtin
  check(nodes.all? { |node| node['server'] == '127.0.0.1' }, 'public node is not a loopback placeholder')
  check(group_list.size == groups.size && known.uniq == known, 'duplicate node/group name')
  done = {}
  groups.each do |name, group|
    refs = group.fetch('proxies', [])
    used = group.fetch('use', [])
    check(refs.any? || used.any? || group['include-all'], "empty group #{name}")
    check((refs - known).empty?, "missing proxy in #{name}")
    check((used - config.fetch('proxy-providers').keys).empty?, "missing proxy provider in #{name}")
    visit(name, groups, {}, done)
  end
  { 'AppleAI' => [US, '🇺🇸 美国-1', '🇺🇸 美国-2', '🇺🇸 US+', 'DIRECT'],
    'PrivateRelay' => [US, '🇺🇸 US+', 'DIRECT'] }.each do |name, refs|
    check(groups.fetch(name).values_at('type', 'proxies') == ['select', refs], "#{name} candidates")
  end
  { 'AI' => US, 'Apple' => 'DIRECT', 'AppleProxy' => MAIN }.each do |name, first|
    check(groups.fetch(name).fetch('proxies').first == first, "#{name} default")
  end
  check(rules.first(2) == %w[GEOSITE,private,DIRECT RULE-SET,AgPrivate,DIRECT], 'private precedence')
  check(rules.last == 'MATCH,Global', 'MATCH fallback')
  ad_index = rules.index('GEOSITE,category-ads-all,REJECT')
  ai_index = rules.index('RULE-SET,AgAI,AI')
  finance_index = rules.index('RULE-SET,Finance,Banking')
  check(ad_index && ai_index && finance_index && ai_index < ad_index && finance_index < ad_index &&
        rules.include?('RULE-SET,AdvertisingLite,REJECT'), 'AI / Finance / ads order')
  rules.each do |rule|
    kind, value, target = rule.split(',')
    check(%w[DOMAIN DOMAIN-SUFFIX DOMAIN-KEYWORD RULE-SET GEOSITE GEOIP IP-CIDR IP-CIDR6 MATCH].include?(kind),
          "unmodeled rule or blanket protocol/port rule: #{kind}")
    check(known.include?(kind == 'MATCH' ? value : target), "missing rule target: #{kind}")
    check(config.fetch('rule-providers').key?(value), "missing provider #{value}") if kind == 'RULE-SET'
  end
  check(rules.uniq == rules, 'duplicate main rule')
  dns = config.fetch('dns')
  check(dns[index.zero? ? 'respect-rules' : 'follow-rule'] == true, 'DNS rule following')
  domains = dns.fetch('nameserver-policy').flat_map { |key, upstreams| key.split(',').map { |k| [k, upstreams] } }
  check(domains.map(&:first).uniq.size == domains.size, 'duplicate DNS domain key')
  (APPLE_DNS.map { |host| [host, OVERSEAS] } +
    %w[sync.icloud.com appldnld.apple.com music.apple.com].map { |host| [host, DOMESTIC] }).each do |host, expected|
    matching = domains.select do |key, _|
      key.start_with?('+.') ? domain_match?("DOMAIN-SUFFIX,#{key[2..-1]}", host) : key == host
    end
    best = matching.max_by { |key, _| key.delete_prefix('+.').length }
    check(best && best.last == expected, "DNS #{host}")
  end
  puts "#{index.zero? ? 'Clash' : 'Stash'} #{rules.size} rules, #{groups.size} groups, #{config['rule-providers'].size} providers"
end

cases = [
  ['apple-relay.cloudflare.com', 'TCP/443', 'AppleAI'],
  ['apple-relay.fastly-edge.com', 'UDP/443', 'AppleAI'],
  ['cp4.cloudflare.com', 'UDP/443', 'AppleAI'],
  ['apple-relay.apple.com', 'TCP/443', 'AppleAI'],
  ['guzzoni.apple.com', 'TCP/443', 'AppleAI'],
  ['search.smoot.apple.com', 'TCP/443', 'AppleAI'],
  ['mask.icloud.com', 'UDP/443', 'PrivateRelay'],
  ['mask-h2.icloud.com', 'TCP/443', 'PrivateRelay'],
  ['mask-api.icloud.com', 'TCP/443', 'PrivateRelay'],
  ['mask.apple-dns.net', 'UDP/443', 'PrivateRelay'],
  ['chatgpt.com', 'UDP/443', 'AI'],
  ['gemini.google.com', 'TCP/443', 'AI'],
  ['video.googlevideo.com', 'UDP/443', 'GMedia'],
  ['appldnld.apple.com', 'TCP/443', 'Apple'],
  ['www.baidu.com', 'UDP/443', 'DIRECT'],
  ['adservice.google.com', 'UDP/443', 'REJECT'],
  ['apple-relay.akamaized.net', 'UDP/443', 'AI'],
  ['guzzoni-apple-com.v.aaplimg.com', 'TCP/443', 'AI'],
  ['sync.icloud.com', 'TCP/443', 'Apple'],
  ['apps.apple.com', 'TCP/443', 'Apple'],
  ['play-edge.itunes.apple.com', 'TCP/443', 'AppleProxy'],
  ['hls-svod.itunes.apple.com', 'TCP/443', 'GMedia'],
  ['music.apple.com', 'TCP/443', 'Apple'],
  ['unlisted-overseas.example', 'UDP/443', 'Global'],
  ['wise.com', 'TCP/443', 'Banking'],
  ['paypalobjects.com', 'TCP/443', 'PayPal'],
  ['bochk.com', 'TCP/443', 'DIRECT'],
  ['spotifycdn.com', 'TCP/443', 'DIRECT'],
  ['castle.io', 'TCP/443', 'AI']
]
INTERCOM.each do |host|
  cases << [host, 'TCP/443', MAIN]
  check(!providers.fetch('AgAI').any? { |rule| domain_match?(rule, host) }, "AI.yaml overlaps Intercom #{host}")
end
qx = %w[QX_AI.list Finance.list Private.list].map do |file|
  File.readlines(File.join(ROOT, file), chomp: true).reject { |line| line.empty? || line.start_with?('#') }
end
INTERCOM.each do |host|
  matches = qx.flatten.select do |line|
    domain_match?(line.sub(/\AHOST(?=,|-)/, 'DOMAIN'), host)
  end
  check(matches == ["HOST-SUFFIX,#{host},#{MAIN}"], "QX Intercom overlap #{host}")
end
check(providers.fetch('Finance').any? { |rule| domain_match?(rule, 'castle.io') }, 'castle.io overlap audit')

# The model uses domain inputs only. Protocol and port label each case, and the
# structure check above rejects rule types that could make this model inaccurate.
cases.each_with_index do |(host, transport, expected), index|
  result, rule = classify(configs[0].fetch('rules'), host, providers, geosite)
  check(result == expected, "#{host}: expected #{expected}, got #{result}")
  puts format('R%02d %s %-37s %s (%s)', index + 1, transport, host, result, rule)
end
puts "PASS #{cases.size} domain-route assertions on identical Clash / Stash rules, plus QX Intercom checks"
