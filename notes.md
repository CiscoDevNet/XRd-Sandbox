# Notes

Images names:

```
ios-xr/xrd-control-plane:24.4.2
ios-xr/xrd-control-plane:25.1.2
```

# extract tar

```
# filename
xrd-control-plane-container-x86.24.4.2.tgz

cd xrd-control-plane-container-x86.24.4.2
docker load -i load -i xrd-control-plane-container-x64.dockerv1.tgz
```

get the interface

```
ip -o -4 addr show | awk '/10\.10\.20\.15\/24/ {print $2}'
```
