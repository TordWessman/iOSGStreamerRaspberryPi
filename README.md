# iOSGStreamerRaspberryPi

Example application for streaming H.264 encoded video from a Raspberry Pi using Gstreamer.

In order for this application to work, one must install the Gstreamer SDK (http://docs.gstreamer.com/display/GstSDK/Installing+for+iOS+development).

## Example Gstreamer pipelines on the server side:

- Using the raspivid command:

$ raspivid -t 0 -h 240 -w 320 -fps 30 -vf -hf -b 16536 -o - | gst-launch-1.0 -v fdsrc ! h264parse ! rtph264pay config-interval=1  ! gdppay ! queue leaky=1 max-size-buffers=4 ! tcpserversink port=(HostPort) host=(HostIp)

- Using the rpicam Gstreamer plugin:

$ gst-launch-1.0 -v rpicamsrc preview=false bitrate=524288 keyframe-interval=24 ! video/x-h264,  parsed=true, stream-format="byte-stream", alignment="au", level="4", profile="high", framerate=30/1,width=1024,height=768 ! rtph264pay config-interval=1 ! gdppay ! queue leaky=2 ! tcpserversink port=(HostPort) host=(HostIp)