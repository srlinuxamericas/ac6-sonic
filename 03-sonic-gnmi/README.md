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
  --update-value '{"route_operation":"permit","match_protocol":"ospf","set_asn":"65501"}' \
  --update-path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/TEST_GNMI_SET|20' \
  --update-value '{"route_operation":"permit","match_protocol":"isis","set_asn":"65501"}'

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
    },
    {
      "operation": "UPDATE",
      "path": "sonic-db:/CONFIG_DB/localhost/ROUTE_MAP/TEST_GNMI_SET|20"
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
    "timestamp": 1794415291243669903,
    "time": "2026-11-11T10:41:31.243669903-06:00",
    "updates": [
      {
        "Path": "sonic-db:/CONFIG_DB/localhost/ROUTE_MAP|TEST_GNMI_SET",
        "values": {
          "CONFIG_DB/localhost/ROUTE_MAP|TEST_GNMI_SET": {
            "TEST_GNMI_SET|10": {
              "match_protocol": "ospf",
              "route_operation": "permit",
              "set_asn": "65501"
            },
            "TEST_GNMI_SET|20": {
              "match_protocol": "isis",
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

Now let's delete this route policy statement 10:

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

Now try the gNMI GET again to see if the policy and remaining statement exists.

```bash
gnmic -a spine11:8080 --insecure   -e json_ietf get   --path 'sonic-db:/CONFIG_DB/localhost/ROUTE_MAP|TEST_GNMI_SET'
```

Expected output:

```bash
[
  {
    "source": "spine11:8080",
    "timestamp": 1794415463776377647,
    "time": "2026-11-11T10:44:23.776377647-06:00",
    "updates": [
      {
        "Path": "sonic-db:/CONFIG_DB/localhost/ROUTE_MAP",
        "values": {
          "CONFIG_DB/localhost/ROUTE_MAP": {
            "TEST_GNMI_SET|20": {
              "match_protocol": "isis",
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

The policy statement 10 does not exist anymore since it was successfully deleted.



## Next Section:   [SONiC Dashboards](https://github.com/srlinuxamericas/ac6-sonic/tree/main/04-sonic-dashboards)
