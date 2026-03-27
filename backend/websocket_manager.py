from typing import Dict, List
from fastapi import WebSocket
import json
import asyncio
from datetime import datetime

class ConnectionManager:
    def __init__(self):
        # Store active connections: {chat_room_id: [websockets]}
        self.active_connections: Dict[int, List[WebSocket]] = {}
        # Store user info: {websocket: {"user_id": int, "user_name": str, "chat_room_id": int}}
        self.connection_info: Dict[WebSocket, Dict] = {}

    async def connect(self, websocket: WebSocket, chat_room_id: int, user_id: int, user_name: str):
        """Accept WebSocket connection and add to chat room"""
        await websocket.accept()
        
        # Add to chat room
        if chat_room_id not in self.active_connections:
            self.active_connections[chat_room_id] = []
        self.active_connections[chat_room_id].append(websocket)
        
        # Store connection info
        self.connection_info[websocket] = {
            "user_id": user_id,
            "user_name": user_name,
            "chat_room_id": chat_room_id
        }
        
        # Notify others that user joined
        await self.broadcast_to_room(chat_room_id, {
            "type": "user_joined",
            "user_name": user_name,
            "timestamp": datetime.utcnow().isoformat()
        }, exclude_websocket=websocket)

    def disconnect(self, websocket: WebSocket):
        """Remove WebSocket connection"""
        if websocket in self.connection_info:
            info = self.connection_info[websocket]
            chat_room_id = info["chat_room_id"]
            user_name = info["user_name"]
            
            # Remove from chat room
            if chat_room_id in self.active_connections:
                if websocket in self.active_connections[chat_room_id]:
                    self.active_connections[chat_room_id].remove(websocket)
                
                # Clean up empty chat rooms
                if not self.active_connections[chat_room_id]:
                    del self.active_connections[chat_room_id]
            
            # Remove connection info
            del self.connection_info[websocket]
            
            # Notify others that user left (async, so we'll handle this separately)
            asyncio.create_task(self.broadcast_to_room(chat_room_id, {
                "type": "user_left",
                "user_name": user_name,
                "timestamp": datetime.utcnow().isoformat()
            }))

    async def send_personal_message(self, message: dict, websocket: WebSocket):
        """Send message to specific WebSocket"""
        try:
            await websocket.send_text(json.dumps(message))
        except:
            # Connection might be closed
            self.disconnect(websocket)

    async def broadcast_to_room(self, chat_room_id: int, message: dict, exclude_websocket: WebSocket = None):
        """Send message to all connections in a chat room"""
        if chat_room_id in self.active_connections:
            disconnected_websockets = []
            
            for websocket in self.active_connections[chat_room_id]:
                if websocket != exclude_websocket:
                    try:
                        await websocket.send_text(json.dumps(message))
                    except:
                        # Connection is closed, mark for removal
                        disconnected_websockets.append(websocket)
            
            # Clean up disconnected websockets
            for websocket in disconnected_websockets:
                self.disconnect(websocket)

    async def send_message_to_room(self, chat_room_id: int, sender_websocket: WebSocket, message_data: dict):
        """Send chat message to all users in room"""
        if sender_websocket in self.connection_info:
            sender_info = self.connection_info[sender_websocket]
            
            message = {
                "type": "message",
                "chat_room_id": chat_room_id,
                "message": message_data["message"],
                "sender_id": sender_info["user_id"],
                "sender_name": sender_info["user_name"],
                "timestamp": datetime.utcnow().isoformat()
            }
            
            # Send to all users in the room
            await self.broadcast_to_room(chat_room_id, message)

    def get_room_users(self, chat_room_id: int) -> List[dict]:
        """Get list of users currently in chat room"""
        users = []
        if chat_room_id in self.active_connections:
            for websocket in self.active_connections[chat_room_id]:
                if websocket in self.connection_info:
                    info = self.connection_info[websocket]
                    users.append({
                        "user_id": info["user_id"],
                        "user_name": info["user_name"]
                    })
        return users

# Global connection manager instance
manager = ConnectionManager()