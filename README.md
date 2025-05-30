# Demo Flutter WebSocket Chat Application

## Project Purpose

This demo Flutter application showcases a real-time chat application built using WebSockets. It allows users to send and receive message and manage users in a simple and intuitive interface. This application is intended for developers who want to learn how to implement real-time communication in their Flutter apps using WebSockets.

## Setup Instructions

### Prerequisites

*   Flutter SDK (version ^3.32.0 or higher)
*   Dart SDK (version ^3.8.1 or higher)

### Installation

1.  Clone the repository:
    ```bash
    git clone https://github.com/your-username/demo_flutter_websocket_chat.git
    ```
2.  Navigate to the project directory:
    ```bash
    cd demo_flutter_websocket_chat
    ```
3.  Install dependencies:
    ```bash
    flutter pub get
    ```

### Configuration

No specific configuration is required for this demo application. However, you may need to configure your WebSocket server endpoint in the client application if you are using a custom server.

## Usage Examples

### Basic Usage
1.  Run the websocket server:
    ```bash
    cd server
    dart run bin/server.dart
    ```
2.  Run the Flutter application:
    ```bash
    cd client
    flutter run
    ```
3.  Enter your username and join a chat room.
4.  Start sending and receiving messages in real-time.
