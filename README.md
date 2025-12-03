# Pomfret VISTA Observatory Control System

macOS application for controlling the Pomfret School VISTA Observatory, including roof control, environmental monitoring, and all-sky camera systems.

## System Architecture

### Components

1. **SwiftUI Application** (this project)
   - Runs on any Mac (macOS 13.0+)
   - Provides unified control interface
   - Displays real-time camera feeds
   - Monitors environmental conditions
   - Controls observatory roof and equipment

2. **Camera Service** (`camera_service.py`)
   - Runs on Mac Mini at observatory site
   - Controls ASI all-sky cameras (120MC/676MC)
   - Provides HTTP API and MJPEG video stream
   - Requires: Python 3, Flask, NumPy, Pillow

3. **Hardware Controllers**
   - Roof control system
   - Environmental sensors (temperature, humidity)
   - Side-wall panels (future)

## Quick Start

### Running the Application

1. Open `Pomfret VISTA Observatory.xcodeproj` in Xcode
2. Build and run (⌘R)
3. Login with password: `VISTAobs`
4. Configure controllers in Settings

### Setting up Camera Service (Mac Mini)

1. Install dependencies:
```bash
pip3 install flask flask-cors pillow numpy
brew install libusb
```

2. Run the service:
```bash
cd ~/Desktop
python3 camera_service.py
```

3. Service will run on `http://[MAC_MINI_IP]:8080`

### Adding Controllers

1. Go to **Settings** tab
2. Click **Add Controller** or edit existing
3. Configure:
   - **Name**: Descriptive name
   - **Base URL**: `http://[IP_ADDRESS]:8080`
   - **Roles**: Select what this controller handles:
     - Roof Control
     - Side-wall Control
     - Environment Sensors
     - Cameras
4. Click **Connect**

## Features

### Roof Control
- Open/close observatory roof
- Emergency stop
- Magnetic lock control
- Real-time status monitoring

### Camera System
- ASI 120MC / 676MC all-sky cameras
- Real-time MJPEG video streaming
- Snapshot capture
- Adjustable exposure and gain

### Environmental Monitoring
- Temperature and humidity sensors
- Weather data integration
- Safety checks (rain, wind, door status)

### Multi-Controller Support
- Connect to multiple hardware controllers
- Each controller can have multiple roles
- Automatic status refresh every 5 seconds
- Comprehensive logging system

## Project Structure

```
Sources/
├── APIClient.swift              # HTTP API client
├── AppState.swift               # Application state management
├── ObservatoryApp.swift         # Main app entry point
├── ContentView.swift            # Main navigation
├── MenuBarPresenter.swift       # Menu bar status
├── Models/
│   ├── ControllerState.swift   # Controller management
│   └── WeatherClient.swift     # Weather data fetching
├── Views/
│   ├── LoginView.swift          # Authentication
│   ├── RoofView.swift           # Roof control interface
│   ├── SensorsView.swift        # Sensors & cameras
│   ├── WeatherView.swift        # Weather display
│   ├── LogsView.swift           # System logs
│   ├── SettingsView.swift       # Configuration
│   └── Components/
│       ├── MJPEGStreamView.swift  # Video stream display
│       ├── StatusBadge.swift      # Status indicators
│       └── ConfirmDialog.swift    # Confirmation dialogs
└── Bridging/
    └── ASICamera2-Bridging-Header.h

camera_service.py                # Camera control service (for Mac Mini)

ThirdParty/
└── ASISDK/                      # ASI Camera SDK
    ├── include/
    └── lib/
```

## Camera Service API

### Endpoints

- `GET /status` - Get camera and sensor status
- `POST /camera/stream/start` - Start video streaming
- `POST /camera/stream/stop` - Stop video streaming
- `GET /camera/snapshot` - Capture single image
- `GET /camera/stream` - MJPEG video stream

### Status Response Format

```json
{
  "sensors": {
    "temperature": null,
    "humidity": null,
    "weatherCam": {
      "connected": true,
      "streaming": false,
      "lastSnapshot": "2025-12-02T20:00:00Z",
      "fault": null
    },
    "meteorCam": {
      "connected": true,
      "streaming": false,
      "lastSnapshot": "2025-12-02T20:00:00Z",
      "fault": null
    }
  }
}
```

## Hardware

### Current Setup
- **Camera**: ZWO ASI 120MC (1280x960, color)
- **Future**: ZWO ASI 676MC (3008x3008, color)
- **Mac Mini**: Intel, running camera service
- **Network**: Local network connection required

### Camera Specifications

**ASI 120MC**
- Resolution: 1280 x 960
- Pixel Size: 3.75μm
- Color sensor
- USB 3.0 interface

**ASI 676MC** (when available)
- Resolution: 3008 x 3008
- Pixel Size: 2.0μm
- Color sensor
- USB 3.0 interface

## Development

### Requirements
- Xcode 15.0+
- macOS 13.0+ (deployment target)
- Swift 5.9+

### Building
```bash
open "Pomfret VISTA Observatory.xcodeproj"
# Build in Xcode (⌘B)
```

## Troubleshooting

### Camera Not Connecting
- Check USB connection to Mac Mini
- Verify `libusb` is installed: `brew install libusb`
- Check camera service is running
- Verify network connectivity

### Video Stream Not Displaying
- Ensure camera is streaming (check status)
- Test stream in browser: `http://[MAC_MINI_IP]:8080/camera/stream`
- Check network connection
- Review logs in application

### Application Crashes on Login
- Ensure no controllers are configured to auto-connect
- Check network connectivity
- Review crash logs

## License

Pomfret School VISTA Observatory Project

## Contact

Pomfret School
Physics & Astronomy Department
