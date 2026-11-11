# gNMI Operations with SONiC

In this section, we will practise gNMI Get, Set and Subscribe commands and our target node will be `spine11`.

All gNMI requests will be sent from the VM using `gnmic`.

## gNMI Capabilities

Let's start with the basic gNMI `Capabilities` RPC. This is often used to check where the switch is responding to gNMI requests.

Run the command from the VM:

```bash
gnmic -a spine11:8080 -u admin -p admin --insecure cap
```

Expected output:

```bash
gNMI version: 0.7.0
supported models:
  - openconfig-acl, OpenConfig working group, 1.0.2
  - openconfig-interfaces, OpenConfig working group, 
  - openconfig-mclag, OpenConfig working group, 
  - openconfig-sampling-sflow, OpenConfig working group, 
  - openconfig-acl, OpenConfig working group, 
  - openconfig-lldp, OpenConfig working group, 1.0.2
  - openconfig-platform, OpenConfig working group, 1.0.2
  - openconfig-system, OpenConfig working group, 1.0.2
  - ietf-yang-library, IETF NETCONF (Network Configuration) Working Group, 2016-06-21
  - sonic-db, SONiC, 0.1.0
supported encodings:
  - JSON
  - JSON_IETF
  - PROTO
```

## gNMI Get

In the previous section, we pushed BGP configuration to `spine11`. Let's use gNMI GET RPCs to retrieve configuration and state for BGP.

Run the below command from the VM to get the BGP neighbor configuration.

```bash
gnmic -a spine11:8080 --insecure   -e json_ietf get   --path 'sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR/default|1.1.1.1'
```

Expected output:

```bash
[
  {
    "source": "spine11:8080",
    "timestamp": 1794000635895949058,
    "time": "2026-11-06T15:30:35.895949058-06:00",
    "updates": [
      {
        "Path": "sonic-db:/CONFIG_DB/localhost/BGP_NEIGHBOR/default|1.1.1.1",
        "values": {
          "CONFIG_DB/localhost/BGP_NEIGHBOR/default|1.1.1.1": {
            "asn": "64501",
            "ebgp_multihop_ttl": "2",
            "local_addr": "11.11.11.11"
          }
        }
      }
    ]
  }
]
```

## gNMI Set

Let's create a Route policy using gNMI Set.

```bash
gnmic -a spine11:8080 -u admin -p admin --insecure \
  -e json_ietf set \
  --update-path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/TEST_GNMI_SET|10' \
  --update-value '{"route_operation": "permit","match_protocol": "ospf","set_asn": "65501"}'
  --update-path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/TEST_GNMI_SET|20' \
  --update-value '{"route_operation": "permit","match_protocol": "isis","set_asn": "65501"}'
```

Expected output:

```bash
{
  "source": "spine11:8080",
  "time": "1969-12-31T18:00:00-06:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/TEST_GNMI_SET|10"
    }
  ]
}
```

Now let's query that route policy using gNMI GET:

```bash
gnmic -a spine11:8080 --insecure   -e json_ietf get   --path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP|TEST_GNMI_SET'
```

Expected output:

```bash
[
  {
    "source": "spine11:8080",
    "timestamp": 1794002538859732945,
    "time": "2026-11-06T16:02:18.859732945-06:00",
    "updates": [
      {
        "Path": "sonic-db:/CONFIG_DB/localhost/ROUTE_MAP|TEST_GNMI_SET",
        "values": {
          "CONFIG_DB/localhost/ROUTE_MAP|TEST_GNMI_SET": {
            "TEST_GNMI_SET|10": {
              "match_protocol": "ospf",
              "route_operation": "permit",
              "set_asn": "65501"
            }
          }
        }
      }
    ]
  }
]
```

That confirms our route policy was successfully provisioned.

Now let's delete this route policy:

```bash
gnmic -a spine11:8080 --insecure   -e json_ietf set   --delete 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/TEST_GNMI_SET|10'
```

Expected output:

```bash
{
  "source": "spine11:8080",
  "time": "1969-12-31T18:00:00-06:00",
  "results": [
    {
      "operation": "DELETE",
      "path": "sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/TEST_GNMI_SET|10"
    }
  ]
}
```

Now try the gNMI GET again to see if the policy exists.

```bash
gnmic -a spine11:8080 --insecure   -e json_ietf get   --path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP|TEST_GNMI_SET'
```

Expected output:

```bash
target "spine11:8080" Get request failed: "spine11:8080" GetRequest failed: rpc error: code = NotFound desc = Failed to find CONFIG_DB ROUTE_MAP|TEST_GNMI_SET <nil> []
Error: one or more requests failed
```

The policy does not exist anymore since it was successfully deleted.

## gNMI Subscribe

The Subscribe RPC is the most commonly used gNMI RPC and provides Streaming Telemetry.

We will try 2 different telemetry options during this workshop.

### Sample

If we need a continous stream of a counter, we will use the `SAMPLE` option along with a specific interval.

The following command streams the in packets value every 5 seconds for interface `Ethernet0` on `spine11`.

```bash
gnmic -a spine11:8080   -u admin -p admin   --insecure   subscribe   --target COUNTERS_DB   --mode stream   --stream-mode sample   --sample-interval 5s --path "COUNTERS/Ethernet0/SAI_PORT_STAT_IF_IN_UCAST_PKTS"
```

The streaming session can be stopped using `CTRL+c`.


### On change

In some cases, we only want a counter when the value has changed. For example, after a new interface is configured, the in packets will be 0 until a protocol and neighbor are established. There is no benefit in streaming continous zeros.

This is where the `ON-CHANGE` option comes to the rescue.

When this option is enabled, the system will only stream data when the value of the object has changed.

Let us stream the same in packets counter using this method.

```bash
gnmic -a spine11:8080   -u admin -p admin   --insecure   subscribe   --target COUNTERS_DB   --mode stream   --stream-mode on-change   --path "COUNTERS/Ethernet0/SAI_PORT_STAT_IF_IN_UCAST_PKTS"
```

You will notice that the system is not streaming this counter as there is no change in the counter value.

Keep the streaming session going and open another window to `leaf11`. Start a ping from `leaf11` to the `spine11` interface.

On **leaf11**:

```bash
ping 192.168.10.3
```

While ping is in progress, check the streaming output. There should be a continous stream of the counter for every increment in the packet count.

Stop the ping using `CTRL+c` and check the streaming output again. The stream has slowed down or is not streaming any more as there is no change in the counter value.

Stop the streaming session using `CTRL+c`.

## Next Section:   [SONiC Dashboards](https://github.com/srlinuxamericas/ac6-sonic/tree/main/04-sonic-dashboards)
