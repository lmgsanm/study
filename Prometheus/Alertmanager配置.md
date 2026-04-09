[Alertmanager](https://github.com/prometheus/alertmanager)是通过命令行选项和配置文件配置的。虽然命令行选项配置不可变的系统参数，但配置文件定义了抑制规则、通知路由和通知接收者。

要查看所有可用的命令行选项，请运行： `alertmanager -h`。

Alertmanager可以在运行时重新加载配置。如果新配置有格式错误，将不会应用更改，并记录错误。通过向进程发送`SIGHUP`或向`/-/reload`端点发送HTTP POST请求来触发配置重新加载。

https://prometheus.io/docs/alerting/latest/configuration/

## 配置文件

要指定要加载哪个配置文件，请使用 `--config.file`选项。

```bash
./alertmanager --config.file=simple.yml
```

该文件以YAML格式编写，由下面描述的shcema进行定义。方括号表示参数是可选的。对于非列表参数，该值设置为指定的默认值。

通用占位符的定义如下：

- `<duration>`：匹配正则表达式 `[0-9]+(ms|[smhdwy])`的持续时长
- `<labelname>`：匹配正则表达式`[a-zA-Z_][a-zA-Z0-9_]*`的字符串
- `<labelvalue>`：unicode字符串
- `<filepath>`：在当前工作目录的有效路径
- `<boolean>`：一个可以取`true`或`false`值的布尔值
- `<string>`：常规字符串
- `<secret>`：保密的常规字符串，如密码
- `<tmpl_string>`：在使用之前经过模板扩展的字符串
- `<tmpl_secret>`：在使用之前模板扩展的字符串，这是一个secret

其他占位符是单独指定的。

这里提供了一个上下文使用的[有效示例文件](https://github.com/prometheus/alertmanager/blob/master/doc/examples/simple.yml)。

全局配置指定在所有其他配置上下文中有效的参数。它们还可以作为其他配置部分的默认值。

```yaml
global:
  # The default SMTP From header field.
  [ smtp_from: <tmpl_string> ]
  # The default SMTP smarthost used for sending emails, including port number.
  # Port number usually is 25, or 587 for SMTP over TLS (sometimes referred to as STARTTLS).
  # Example: smtp.example.org:587
  [ smtp_smarthost: <string> ]
  # The default hostname to identify to the SMTP server.
  [ smtp_hello: <string> | default = "localhost" ]
  # SMTP Auth using CRAM-MD5, LOGIN and PLAIN. If empty, Alertmanager doesn't authenticate to the SMTP server.
  [ smtp_auth_username: <string> ]
  # SMTP Auth using LOGIN and PLAIN.
  [ smtp_auth_password: <secret> ]
  # SMTP Auth using LOGIN and PLAIN.
  [ smtp_auth_password_file: <string> ]
  # SMTP Auth using PLAIN.
  [ smtp_auth_identity: <string> ]
  # SMTP Auth using CRAM-MD5.
  [ smtp_auth_secret: <secret> ]
  # The default SMTP TLS requirement.
  # Note that Go does not support unencrypted connections to remote SMTP endpoints.
  [ smtp_require_tls: <bool> | default = true ]

  # The API URL to use for Slack notifications.
  [ slack_api_url: <secret> ]
  [ slack_api_url_file: <filepath> ]
  [ victorops_api_key: <secret> ]
  [ victorops_api_key_file: <filepath> ]
  [ victorops_api_url: <string> | default = "https://alert.victorops.com/integrations/generic/20131114/alert/" ]
  [ pagerduty_url: <string> | default = "https://events.pagerduty.com/v2/enqueue" ]
  [ opsgenie_api_key: <secret> ]
  [ opsgenie_api_key_file: <filepath> ]
  [ opsgenie_api_url: <string> | default = "https://api.opsgenie.com/" ]
  [ wechat_api_url: <string> | default = "https://qyapi.weixin.qq.com/cgi-bin/" ]
  [ wechat_api_secret: <secret> ]
  [ wechat_api_corp_id: <string> ]
  [ telegram_api_url: <string> | default = "https://api.telegram.org" ]
  [ webex_api_url: <string> | default = "https://webexapis.com/v1/messages" ]
  # The default HTTP client configuration
  [ http_config: <http_config> ]

  # ResolveTimeout is the default value used by alertmanager if the alert does
  # not include EndsAt, after this time passes it can declare the alert as resolved if it has not been updated.
  # This has no impact on alerts from Prometheus, as they always include EndsAt.
  [ resolve_timeout: <duration> | default = 5m ]

# Files from which custom notification template definitions are read.
# The last component may use a wildcard matcher, e.g. 'templates/*.tmpl'.
templates:
  [ - <filepath> ... ]

# The root node of the routing tree.
route: <route>

# A list of notification receivers.
receivers:
  - <receiver> ...

# A list of inhibition rules.
inhibit_rules:
  [ - <inhibit_rule> ... ]

# DEPRECATED: use time_intervals below.
# A list of mute time intervals for muting routes.
mute_time_intervals:
  [ - <mute_time_interval> ... ]

# A list of time intervals for muting/activating routes.
time_intervals:
  [ - <time_interval> ... ]
```

## `<route>`

`<route>`块定义路由树中的节点及其子节点。如果未设置，则从其父节点继承其可选配置参数。

每个告警在配置的顶级路由进入路由树，它必须匹配所有告警（即没有任何配置的匹配器）。然后遍历子节点。如果`continue`设置为`false`，那么它将在第一个匹配的子节点之后停止。如果在匹配节点上`continue`为`true`，则告警将继续匹配后续的兄弟节点。如果告警不匹配节点的任何子节点（没有匹配的子节点，或者根本不存在），则根据当前节点的配置参数处理告警。

```php
[ receiver: <string> ]
# The labels by which incoming alerts are grouped together. For example,
# multiple alerts coming in for cluster=A and alertname=LatencyHigh would
# be batched into a single group.
#
# To aggregate by all possible labels use the special value '...' as the sole label name, for example:
# group_by: ['...']
# This effectively disables aggregation entirely, passing through all
# alerts as-is. This is unlikely to be what you want, unless you have
# a very low alert volume or your upstream notification system performs
# its own grouping.
[ group_by: '[' <labelname>, ... ']' ]

# Whether an alert should continue matching subsequent sibling nodes.
[ continue: <boolean> | default = false ]

# DEPRECATED: Use matchers below.
# A set of equality matchers an alert has to fulfill to match the node.
match:
  [ <labelname>: <labelvalue>, ... ]

# DEPRECATED: Use matchers below.
# A set of regex-matchers an alert has to fulfill to match the node.
match_re:
  [ <labelname>: <regex>, ... ]

# A list of matchers that an alert has to fulfill to match the node.
matchers:
  [ - <matcher> ... ]

# How long to initially wait to send a notification for a group
# of alerts. Allows to wait for an inhibiting alert to arrive or collect
# more initial alerts for the same group. (Usually ~0s to few minutes.)
[ group_wait: <duration> | default = 30s ]

# How long to wait before sending a notification about new alerts that
# are added to a group of alerts for which an initial notification has
# already been sent. (Usually ~5m or more.)
[ group_interval: <duration> | default = 5m ]

# How long to wait before sending a notification again if it has already
# been sent successfully for an alert. (Usually ~3h or more).
[ repeat_interval: <duration> | default = 4h ]

# Times when the route should be muted. These must match the name of a
# mute time interval defined in the mute_time_intervals section.
# Additionally, the root node cannot have any mute times.
# When a route is muted it will not send any notifications, but
# otherwise acts normally (including ending the route-matching process
# if the `continue` option is not set.)
mute_time_intervals:
  [ - <string> ...]

# Times when the route should be active. These must match the name of a
# time interval defined in the time_intervals section. An empty value
# means that the route is always active.
# Additionally, the root node cannot have any active times.
# The route will send notifications only when active, but otherwise
# acts normally (including ending the route-matching process
# if the `continue` option is not set).
active_time_intervals:
  [ - <string> ...]

# Zero or more child routes.
routes:
  [ - <route> ... ]
```

示例：

```yaml
# The root route with all parameters, which are inherited by the child
# routes if they are not overwritten.
route:
  receiver: 'default-receiver'
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 4h
  group_by: [cluster, alertname]
  # All alerts that do not match the following child routes
  # will remain at the root node and be dispatched to 'default-receiver'.
  routes:
  # All alerts with service=mysql or service=cassandra
  # are dispatched to the database pager.
  - receiver: 'database-pager'
    group_wait: 10s
    matchers:
    - service=~"mysql|cassandra"
  # All alerts with the team=frontend label match this sub-route.
  # They are grouped by product and environment rather than cluster
  # and alertname.
  - receiver: 'frontend-pager'
    group_by: [product, environment]
    matchers:
    - team="frontend"

  # All alerts with the service=inhouse-service label match this sub-route.
  # the route will be muted during offhours and holidays time intervals.
  # even if it matches, it will continue to the next sub-route
  - receiver: 'dev-pager'
    matchers:
      - service="inhouse-service"
    mute_time_intervals:
      - offhours
      - holidays
    continue: true

    # All alerts with the service=inhouse-service label match this sub-route
    # the route will be active only during offhours and holidays time intervals.
  - receiver: 'on-call-pager'
    matchers:
      - service="inhouse-service"
    active_time_intervals:
      - offhours
      - holidays
```

## `<inhibit_rule>`

当告警（源）存在并与另一组匹配器匹配时，抑制规则会破坏与一组匹配器匹配的告警（目标）。对于`equal`列表中的标签名称，目标和源告警必须具有相同的标签值。

为了防止告警本身受到抑制，如果告警与规则的目标和来源方都匹配，则不能通过告警（包括告警本身）来抑制告警。但是，我们建议选择目标匹配器和源匹配器时，采用的方式不能同时发出告警。它更容易理解，而且不会引发这种特殊情况。

```yaml
# DEPRECATED: Use target_matchers below.
# Matchers that have to be fulfilled in the alerts to be muted.
target_match:
  [ <labelname>: <labelvalue>, ... ]
# DEPRECATED: Use target_matchers below.
target_match_re:
  [ <labelname>: <regex>, ... ]

# A list of matchers that have to be fulfilled by the target
# alerts to be muted.
target_matchers:
  [ - <matcher> ... ]

# DEPRECATED: Use source_matchers below.
# Matchers for which one or more alerts have to exist for the
# inhibition to take effect.
source_match:
  [ <labelname>: <labelvalue>, ... ]
# DEPRECATED: Use source_matchers below.
source_match_re:
  [ <labelname>: <regex>, ... ]

# A list of matchers for which one or more alerts have
# to exist for the inhibition to take effect.
source_matchers:
  [ - <matcher> ... ]

# Labels that must have an equal value in the source and target
# alert for the inhibition to take effect.
[ equal: '[' <labelname>, ... ']' ]
```

## `<http_config>`

`http_config`允许配置接收方用来与基于HTTP的API服务通信的HTTP客户端。

```yaml
# Note that `basic_auth` and `authorization` options are mutually exclusive.

# Sets the `Authorization` header with the configured username and password.
# password and password_file are mutually exclusive.
basic_auth:
  [ username: <string> ]
  [ password: <secret> ]
  [ password_file: <string> ]

# Optional the `Authorization` header configuration.
authorization:
  # Sets the authentication type.
  [ type: <string> | default: Bearer ]
  # Sets the credentials. It is mutually exclusive with
  # `credentials_file`.
  [ credentials: <secret> ]
  # Sets the credentials with the credentials read from the configured file.
  # It is mutually exclusive with `credentials`.
  [ credentials_file: <filename> ]

# Optional OAuth 2.0 configuration.
# Cannot be used at the same time as basic_auth or authorization.
oauth2:
  [ <oauth2> ]

# Whether to enable HTTP2.
[ enable_http2: <bool> | default: true ]

# Optional proxy URL.
[ proxy_url: <string> ]

# Configure whether HTTP requests follow HTTP 3xx redirects.
[ follow_redirects: <bool> | default = true ]

# Configures the TLS settings.
tls_config:
  [ <tls_config> ]
```

## `<tls_config>`

`tls_config`用于配置TLS连接。

```yaml
# CA certificate to validate the server certificate with.
[ ca_file: <filepath> ]

# Certificate and key files for client cert authentication to the server.
[ cert_file: <filepath> ]
[ key_file: <filepath> ]

# ServerName extension to indicate the name of the server.
# http://tools.ietf.org/html/rfc4366#section-3.1
[ server_name: <string> ]

# Disable validation of the server certificate.
[ insecure_skip_verify: <boolean> | default = false]

# Minimum acceptable TLS version. Accepted values: TLS10 (TLS 1.0), TLS11 (TLS
# 1.1), TLS12 (TLS 1.2), TLS13 (TLS 1.3).
# If unset, Prometheus will use Go default minimum version, which is TLS 1.2.
# See MinVersion in https://pkg.go.dev/crypto/tls#Config.
[ min_version: <string> ]
# Maximum acceptable TLS version. Accepted values: TLS10 (TLS 1.0), TLS11 (TLS
# 1.1), TLS12 (TLS 1.2), TLS13 (TLS 1.3).
# If unset, Prometheus will use Go default maximum version, which is TLS 1.3.
# See MaxVersion in https://pkg.go.dev/crypto/tls#Config.
[ max_version: <string> ]
```

## `<receiver>`

Receiver是一个或多个通知集成的命名配置。

我们没有积极地添加新的接收者（receiver），我们建议通过[webhook](https://www.coderdocument.com/docs/prometheus/v2.14/alerting/configuration.html#webhook_config)接收者集成自定义通知。

```makefile
# The unique name of the receiver.
name: <string>

# Configurations for several notification integrations.
email_configs:
  [ - <email_config>, ... ]
opsgenie_configs:
  [ - <opsgenie_config>, ... ]
pagerduty_configs:
  [ - <pagerduty_config>, ... ]
pushover_configs:
  [ - <pushover_config>, ... ]
slack_configs:
  [ - <slack_config>, ... ]
sns_configs:
  [ - <sns_config>, ... ]
victorops_configs:
  [ - <victorops_config>, ... ]
webhook_configs:
  [ - <webhook_config>, ... ]
wechat_configs:
  [ - <wechat_config>, ... ]
telegram_configs:
  [ - <telegram_config>, ... ]
webex_configs:
  [ - <webex_config>, ... ]
```

## `<email_config>`

```php
# Whether to notify about resolved alerts.
[ send_resolved: <boolean> | default = false ]

# The email address to send notifications to.
to: <tmpl_string>

# The sender's address.
[ from: <tmpl_string> | default = global.smtp_from ]

# The SMTP host through which emails are sent.
[ smarthost: <string> | default = global.smtp_smarthost ]

# The hostname to identify to the SMTP server.
[ hello: <string> | default = global.smtp_hello ]

# SMTP authentication information.
# auth_password and auth_password_file are mutually exclusive.
[ auth_username: <string> | default = global.smtp_auth_username ]
[ auth_password: <secret> | default = global.smtp_auth_password ]
[ auth_password_file: <string> | default = global.smtp_auth_password_file ]
[ auth_secret: <secret> | default = global.smtp_auth_secret ]
[ auth_identity: <string> | default = global.smtp_auth_identity ]

# The SMTP TLS requirement.
# Note that Go does not support unencrypted connections to remote SMTP endpoints.
[ require_tls: <bool> | default = global.smtp_require_tls ]

# TLS configuration.
tls_config:
  [ <tls_config> ]

# The HTML body of the email notification.
[ html: <tmpl_string> | default = '{{ template "email.default.html" . }}' ]
# The text body of the email notification.
[ text: <tmpl_string> ]

# Further headers email header key/value pairs. Overrides any headers
# previously set by the notification implementation.
[ headers: { <string>: <tmpl_string>, ... } ]
```

## `<hipchat_config>`

HipChat通知使用一个[构建你自己的](https://confluence.atlassian.com/hc/integrations-with-hipchat-server-683508267.html)集成。

```php
# Whether or not to notify about resolved alerts.[ send_resolved: <boolean> | default = false ]# The HipChat Room ID.room_id: <tmpl_string># The auth token.[ auth_token: <secret> | default = global.hipchat_auth_token ]# The URL to send API requests to.[ api_url: <string> | default = global.hipchat_api_url ]# See https://www.hipchat.com/docs/apiv2/method/send_room_notification# A label to be shown in addition to the sender's name.[ from:  <tmpl_string> | default = '{{ template "hipchat.default.from" . }}' ]# The message body.[ message:  <tmpl_string> | default = '{{ template "hipchat.default.message" . }}' ]# Whether this message should trigger a user notification.[ notify:  <boolean> | default = false ]# Determines how the message is treated by the alertmanager and rendered inside HipChat. Valid values are 'text' and 'html'.[ message_format:  <string> | default = 'text' ]# Background color for message.[ color:  <tmpl_string> | default = '{{ if eq .Status "firing" }}red{{ else }}green{{ end }}' ]# The HTTP client's configuration.[ http_config: <http_config> | default = global.http_config ]
```

## `<pagerduty_config>`

PagerDuty通知是通过[PagerDuty API](https://developer.pagerduty.com/documentation/integration/events)发送的。PagerDuty提供了关于如何集成的[文档](https://www.pagerduty.com/docs/guides/prometheus-integration-guide/)。与Alertmanager的v0.11和对PagerDuty事件有更好支持的API v2有重要区别。

```yaml
# Whether or not to notify about resolved alerts.[ send_resolved: <boolean> | default = true ]# The following two options are mutually exclusive.# The PagerDuty integration key (when using PagerDuty integration type `Events API v2`).routing_key: <tmpl_secret># The PagerDuty integration key (when using PagerDuty integration type `Prometheus`).service_key: <tmpl_secret># The URL to send API requests to[ url: <string> | default = global.pagerduty_url ]# The client identification of the Alertmanager.[ client:  <tmpl_string> | default = '{{ template "pagerduty.default.client" . }}' ]# A backlink to the sender of the notification.[ client_url:  <tmpl_string> | default = '{{ template "pagerduty.default.clientURL" . }}' ]# A description of the incident.[ description: <tmpl_string> | default = '{{ template "pagerduty.default.description" .}}' ]# Severity of the incident.[ severity: <tmpl_string> | default = 'error' ]# A set of arbitrary key/value pairs that provide further detail# about the incident.[ details: { <string>: <tmpl_string>, ... } | default = {  firing:       '{{ template "pagerduty.default.instances" .Alerts.Firing }}'  resolved:     '{{ template "pagerduty.default.instances" .Alerts.Resolved }}'  num_firing:   '{{ .Alerts.Firing | len }}'  num_resolved: '{{ .Alerts.Resolved | len }}'} ]# Images to attach to the incident.images:  [ <image_config> ... ]# Links to attach to the incident.links:  [ <link_config> ... ]# The HTTP client's configuration.[ http_config: <http_config> | default = global.http_config ]
```

### `<image_config>`

如下字段被记录在[PagerDuty API文档中](https://v2.developer.pagerduty.com/v2/docs/send-an-event-events-api-v2#section-the-images-property)。

```makefile
href: <tmpl_string>source: <tmpl_string>alt: <tmpl_string>
```

### `<link_config>`

如下字段被记录在[PagerDuty API文档中](https://v2.developer.pagerduty.com/v2/docs/send-an-event-events-api-v2#section-the-links-property)。

```makefile
href: <tmpl_string>text: <tmpl_string>
```

## `<pushover_config>`

Pushover通知是通过[Pushover API](https://pushover.net/api)发送的。

```yaml
# Whether or not to notify about resolved alerts.[ send_resolved: <boolean> | default = true ]# The recipient user’s user key.user_key: <secret># Your registered application’s API token, see https://pushover.net/appstoken: <secret># Notification title.[ title: <tmpl_string> | default = '{{ template "pushover.default.title" . }}' ]# Notification message.[ message: <tmpl_string> | default = '{{ template "pushover.default.message" . }}' ]# A supplementary URL shown alongside the message.[ url: <tmpl_string> | default = '{{ template "pushover.default.url" . }}' ]# Priority, see https://pushover.net/api#priority[ priority: <tmpl_string> | default = '{{ if eq .Status "firing" }}2{{ else }}0{{ end }}' ]# How often the Pushover servers will send the same notification to the user.# Must be at least 30 seconds.[ retry: <duration> | default = 1m ]# How long your notification will continue to be retried for, unless the user# acknowledges the notification.[ expire: <duration> | default = 1h ]# The HTTP client's configuration.[ http_config: <http_config> | default = global.http_config ]
```

## `<slack_config>`

Slack通知是通过[Slack webhook](https://api.slack.com/incoming-webhooks)发送的。通知包含一个[附件](https://api.slack.com/docs/message-attachments)。

```yaml
# Whether or not to notify about resolved alerts.[ send_resolved: <boolean> | default = false ]# The Slack webhook URL.[ api_url: <secret> | default = global.slack_api_url ]# The channel or user to send notifications to.channel: <tmpl_string># API request data as defined by the Slack webhook API.[ icon_emoji: <tmpl_string> ][ icon_url: <tmpl_string> ][ link_names: <boolean> | default = false ][ username: <tmpl_string> | default = '{{ template "slack.default.username" . }}' ]# The following parameters define the attachment.actions:  [ <action_config> ... ][ callback_id: <tmpl_string> | default = '{{ template "slack.default.callbackid" . }}' ][ color: <tmpl_string> | default = '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}' ][ fallback: <tmpl_string> | default = '{{ template "slack.default.fallback" . }}' ]fields:  [ <field_config> ... ][ footer: <tmpl_string> | default = '{{ template "slack.default.footer" . }}' ][ pretext: <tmpl_string> | default = '{{ template "slack.default.pretext" . }}' ][ short_fields: <boolean> | default = false ][ text: <tmpl_string> | default = '{{ template "slack.default.text" . }}' ][ title: <tmpl_string> | default = '{{ template "slack.default.title" . }}' ][ title_link: <tmpl_string> | default = '{{ template "slack.default.titlelink" . }}' ][ image_url: <tmpl_string> ][ thumb_url: <tmpl_string> ]# The HTTP client's configuration.[ http_config: <http_config> | default = global.http_config ]
```

### `<action_config>`

如下字段被记录在[Slack API文档中](https://api.slack.com/docs/message-attachments#action_fields)。

```vbnet
type: <tmpl_string>text: <tmpl_string>url: <tmpl_string>[ style: <tmpl_string> [ default = '' ]
```

### `<field_config>`

如下字段被记录在[Slack API文档中](https://api.slack.com/docs/message-attachments#fields)。

```vbnet
title: <tmpl_string>value: <tmpl_string>[ short: <boolean> | default = slack_config.short_fields ]
```

## `<opsgenie_config>`

OpsGenie通知是通过[OpsGenie API](https://docs.opsgenie.com/docs/alert-api)发送的。

```yaml
# Whether or not to notify about resolved alerts.[ send_resolved: <boolean> | default = true ]# The API key to use when talking to the OpsGenie API.[ api_key: <secret> | default = global.opsgenie_api_key ]# The host to send OpsGenie API requests to.[ api_url: <string> | default = global.opsgenie_api_url ]# Alert text limited to 130 characters.[ message: <tmpl_string> ]# A description of the incident.[ description: <tmpl_string> | default = '{{ template "opsgenie.default.description" . }}' ]# A backlink to the sender of the notification.[ source: <tmpl_string> | default = '{{ template "opsgenie.default.source" . }}' ]# A set of arbitrary key/value pairs that provide further detail# about the incident.[ details: { <string>: <tmpl_string>, ... } ]# List of responders responsible for notifications.responders:  [ - <responder> ... ]# Comma separated list of tags attached to the notifications.[ tags: <tmpl_string> ]# Additional alert note.[ note: <tmpl_string> ]# Priority level of alert. Possible values are P1, P2, P3, P4, and P5.[ priority: <tmpl_string> ]# The HTTP client's configuration.[ http_config: <http_config> | default = global.http_config ]
```

### `<responder>`

```yaml
# Exactly one of these fields should be defined.[ id: <tmpl_string> ][ name: <tmpl_string> ][ username: <tmpl_string> ]# "team", "user", "escalation" or schedule".type: <tmpl_string>
```

## `<victorops_config>`

VictorOps通知是通过[VictorOps API](https://help.victorops.com/knowledge-base/victorops-restendpoint-integration/)发送的。

```php
# Whether or not to notify about resolved alerts.[ send_resolved: <boolean> | default = true ]# The API key to use when talking to the VictorOps API.[ api_key: <secret> | default = global.victorops_api_key ]# The VictorOps API URL.[ api_url: <string> | default = global.victorops_api_url ]# A key used to map the alert to a team.routing_key: <tmpl_string># Describes the behavior of the alert (CRITICAL, WARNING, INFO).[ message_type: <tmpl_string> | default = 'CRITICAL' ]# Contains summary of the alerted problem.[ entity_display_name: <tmpl_string> | default = '{{ template "victorops.default.entity_display_name" . }}' ]# Contains long explanation of the alerted problem.[ state_message: <tmpl_string> | default = '{{ template "victorops.default.state_message" . }}' ]# The monitoring tool the state message is from.[ monitoring_tool: <tmpl_string> | default = '{{ template "victorops.default.monitoring_tool" . }}' ]# The HTTP client's configuration.[ http_config: <http_config> | default = global.http_config ]
```

## `<webhook_config>`

webhook接收者允许配置一个通用的接收者。

```php
# Whether to notify about resolved alerts.
[ send_resolved: <boolean> | default = true ]

# The endpoint to send HTTP POST requests to.
url: <string>

# The HTTP client's configuration.
[ http_config: <http_config> | default = global.http_config ]

# The maximum number of alerts to include in a single webhook message. Alerts
# above this threshold are truncated. When leaving this at its default value of
# 0, all alerts are included.
[ max_alerts: <int> | default = 0 ]
```

Alertmanager将以下JSON格式的HTTP POST请求发送到配置的端点：

```csharp
{
  "version": "4",
  "groupKey": <string>,              // key identifying the group of alerts (e.g. to deduplicate)
  "truncatedAlerts": <int>,          // how many alerts have been truncated due to "max_alerts"
  "status": "<resolved|firing>",
  "receiver": <string>,
  "groupLabels": <object>,
  "commonLabels": <object>,
  "commonAnnotations": <object>,
  "externalURL": <string>,           // backlink to the Alertmanager.
  "alerts": [
    {
      "status": "<resolved|firing>",
      "labels": <object>,
      "annotations": <object>,
      "startsAt": "<rfc3339>",
      "endsAt": "<rfc3339>",
      "generatorURL": <string>,      // identifies the entity that caused the alert
      "fingerprint": <string>        // fingerprint to identify the alert
    },
    ...
  ]
```

该特性有一个[集成](https://prometheus.io/docs/operating/integrations/#alertmanager-webhook-receiver)列表。

## `<wechat_config>`

微信通知是通过[微信API](https://admin.wechat.com/wiki/index.php?title=Customer_Service_Messages)发送的。

```php
# Whether to notify about resolved alerts.
[ send_resolved: <boolean> | default = false ]

# The API key to use when talking to the WeChat API.
[ api_secret: <secret> | default = global.wechat_api_secret ]

# The WeChat API URL.
[ api_url: <string> | default = global.wechat_api_url ]

# The corp id for authentication.
[ corp_id: <string> | default = global.wechat_api_corp_id ]

# API request data as defined by the WeChat API.
[ message: <tmpl_string> | default = '{{ template "wechat.default.message" . }}' ]
# Type of the message type, supported values are `text` and `markdown`.
[ message_type: <string> | default = 'text' ]
[ agent_id: <string> | default = '{{ template "wechat.default.agent_id" . }}' ]
[ to_user: <string> | default = '{{ template "wechat.default.to_user" . }}' ]
[ to_party: <string> | default = '{{ template "wechat.default.to_party" . }}' ]
[ to_tag: <string> | default = '{{ template "wechat.default.to_tag" . }}' ]
```