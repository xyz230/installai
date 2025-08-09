#!/bin/bash

# CatMi - Script di Installazione Automatica per Ubuntu 22.04
# Questo script installa tutto il necessario per far funzionare CatMi su una VPS Ubuntu 22.04

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Domain configuration
DOMAIN="catmi.it"
APP_DIR="/var/www/catmi"
NGINX_CONFIG="/etc/nginx/sites-available/catmi"
SSL_EMAIL="admin@catmi.it"  # Cambia con la tua email per Let's Encrypt

echo -e "${BLUE}🐱 Benvenuto nell'installer di CatMi!${NC}"
echo -e "${BLUE}Questo script installerà tutto il necessario per far funzionare CatMi su Ubuntu 22.04${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ Non eseguire questo script come root. Usa un utente con privilegi sudo.${NC}" 
   exit 1
fi

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️ $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${BLUE}🔄 Aggiornamento del sistema...${NC}"
sudo apt update && sudo apt upgrade -y
print_status "Sistema aggiornato"

echo -e "${BLUE}🔧 Installazione delle dipendenze di base...${NC}"
sudo apt install -y curl wget git vim htop ufw software-properties-common apt-transport-https ca-certificates gnupg lsb-release unzip
print_status "Dipendenze di base installate"

# Install Nginx
echo -e "${BLUE}🌐 Installazione di Nginx...${NC}"
if ! command_exists nginx; then
    sudo apt install -y nginx
    sudo systemctl enable nginx
    sudo systemctl start nginx
    print_status "Nginx installato e avviato"
else
    print_warning "Nginx già installato"
fi

# Install Certbot for SSL
echo -e "${BLUE}🔒 Installazione di Certbot per SSL...${NC}"
if ! command_exists certbot; then
    sudo apt install -y certbot python3-certbot-nginx
    print_status "Certbot installato"
else
    print_warning "Certbot già installato"
fi

# Configure firewall
echo -e "${BLUE}🛡️ Configurazione del firewall...${NC}"
sudo ufw --force enable
sudo ufw allow ssh
sudo ufw allow 'Nginx Full'
sudo ufw allow 80
sudo ufw allow 443
print_status "Firewall configurato"

# Create application directory
echo -e "${BLUE}📁 Creazione directory applicazione...${NC}"
sudo mkdir -p $APP_DIR
sudo chown -R $USER:www-data $APP_DIR
sudo chmod -R 755 $APP_DIR
print_status "Directory $APP_DIR creata"

# Create the CatMi HTML file
echo -e "${BLUE}📝 Creazione file applicazione CatMi...${NC}"
cat > $APP_DIR/index.html << 'EOF'
<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CatMi - AI Assistant</title>
    <script src="https://js.puter.com/v2/"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: #333;
        }

        .container {
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }

        .header {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 20px;
            padding: 25px;
            margin-bottom: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            display: flex;
            align-items: center;
            gap: 20px;
            animation: slideDown 0.8s ease-out;
        }

        @keyframes slideDown {
            from { transform: translateY(-50px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }

        .cat-avatar {
            width: 80px;
            height: 80px;
            background: linear-gradient(135deg, #ff9a56 0%, #ffad56 50%, #ff9a56 100%);
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            font-size: 40px;
            animation: bounce 2s infinite;
            box-shadow: 0 10px 20px rgba(255, 154, 86, 0.3);
        }

        @keyframes bounce {
            0%, 20%, 50%, 80%, 100% { transform: translateY(0); }
            40% { transform: translateY(-10px); }
            60% { transform: translateY(-5px); }
        }

        .header-text {
            flex: 1;
        }

        .header-text h1 {
            font-size: 2.5rem;
            font-weight: 800;
            background: linear-gradient(135deg, #667eea, #764ba2);
            -webkit-background-clip: text;
            -webkit-text-fill-color: transparent;
            margin-bottom: 5px;
        }

        .header-text p {
            color: #666;
            font-size: 1.1rem;
        }

        .status {
            background: linear-gradient(135deg, #4CAF50, #45a049);
            color: white;
            padding: 10px 20px;
            border-radius: 15px;
            font-weight: 600;
            animation: pulse 2s infinite;
        }

        @keyframes pulse {
            0% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0.7); }
            70% { box-shadow: 0 0 0 10px rgba(76, 175, 80, 0); }
            100% { box-shadow: 0 0 0 0 rgba(76, 175, 80, 0); }
        }

        .main-content {
            flex: 1;
            display: grid;
            grid-template-columns: 300px 1fr;
            gap: 20px;
        }

        .sidebar {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 20px;
            padding: 25px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            height: fit-content;
            animation: slideLeft 0.8s ease-out;
        }

        @keyframes slideLeft {
            from { transform: translateX(-50px); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        .chat-history {
            margin-bottom: 25px;
        }

        .chat-history h3 {
            color: #333;
            margin-bottom: 15px;
            font-size: 1.2rem;
        }

        .chat-item {
            padding: 12px;
            background: linear-gradient(135deg, #f8f9ff, #e8f0fe);
            border-radius: 12px;
            margin-bottom: 10px;
            cursor: pointer;
            transition: all 0.3s ease;
            border-left: 4px solid #667eea;
        }

        .chat-item:hover {
            transform: translateX(5px);
            box-shadow: 0 10px 20px rgba(102, 126, 234, 0.2);
        }

        .chat-item.active {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
        }

        .controls {
            display: flex;
            flex-direction: column;
            gap: 15px;
        }

        .btn {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 20px;
            border-radius: 12px;
            cursor: pointer;
            font-weight: 600;
            transition: all 0.3s ease;
            position: relative;
            overflow: hidden;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 15px 30px rgba(102, 126, 234, 0.4);
        }

        .btn:active {
            transform: translateY(0);
        }

        .btn::before {
            content: '';
            position: absolute;
            top: 0;
            left: -100%;
            width: 100%;
            height: 100%;
            background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.2), transparent);
            transition: left 0.5s;
        }

        .btn:hover::before {
            left: 100%;
        }

        .chat-container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(20px);
            border-radius: 20px;
            padding: 25px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            display: flex;
            flex-direction: column;
            animation: slideRight 0.8s ease-out;
        }

        @keyframes slideRight {
            from { transform: translateX(50px); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        .messages {
            flex: 1;
            max-height: 500px;
            overflow-y: auto;
            margin-bottom: 20px;
            padding: 20px;
            background: #f8f9ff;
            border-radius: 15px;
            scrollbar-width: thin;
            scrollbar-color: #667eea #f0f0f0;
        }

        .messages::-webkit-scrollbar {
            width: 6px;
        }

        .messages::-webkit-scrollbar-track {
            background: #f0f0f0;
            border-radius: 3px;
        }

        .messages::-webkit-scrollbar-thumb {
            background: #667eea;
            border-radius: 3px;
        }

        .message {
            margin-bottom: 20px;
            animation: messageSlide 0.5s ease-out;
        }

        @keyframes messageSlide {
            from { transform: translateY(20px); opacity: 0; }
            to { transform: translateY(0); opacity: 1; }
        }

        .message.user {
            text-align: right;
        }

        .message.ai {
            text-align: left;
        }

        .message-content {
            display: inline-block;
            max-width: 80%;
            padding: 15px 20px;
            border-radius: 20px;
            position: relative;
            word-wrap: break-word;
        }

        .message.user .message-content {
            background: linear-gradient(135deg, #667eea, #764ba2);
            color: white;
            border-bottom-right-radius: 5px;
        }

        .message.ai .message-content {
            background: linear-gradient(135deg, #ff9a56, #ffad56);
            color: white;
            border-bottom-left-radius: 5px;
        }

        .input-container {
            display: flex;
            gap: 15px;
            align-items: flex-end;
        }

        .input-wrapper {
            flex: 1;
            position: relative;
        }

        #messageInput {
            width: 100%;
            padding: 15px 20px;
            border: 2px solid #e1e5e9;
            border-radius: 15px;
            font-size: 1rem;
            resize: vertical;
            min-height: 60px;
            max-height: 120px;
            transition: all 0.3s ease;
            background: rgba(255, 255, 255, 0.9);
        }

        #messageInput:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        #sendBtn {
            background: linear-gradient(135deg, #ff9a56, #ffad56);
            border: none;
            padding: 15px 25px;
            border-radius: 15px;
            cursor: pointer;
            font-size: 1.2rem;
            color: white;
            transition: all 0.3s ease;
            min-width: 60px;
            height: 60px;
        }

        #sendBtn:hover {
            transform: scale(1.05);
            box-shadow: 0 10px 20px rgba(255, 154, 86, 0.3);
        }

        #sendBtn:disabled {
            opacity: 0.6;
            cursor: not-allowed;
            transform: none;
        }

        .typing-indicator {
            display: none;
            padding: 15px 20px;
            background: linear-gradient(135deg, #ff9a56, #ffad56);
            border-radius: 20px;
            border-bottom-left-radius: 5px;
            color: white;
            margin-bottom: 20px;
            animation: messageSlide 0.5s ease-out;
        }

        .typing-dots {
            display: inline-block;
        }

        .typing-dots span {
            display: inline-block;
            width: 8px;
            height: 8px;
            border-radius: 50%;
            background: white;
            margin: 0 2px;
            animation: typingDots 1.4s infinite both;
        }

        .typing-dots span:nth-child(1) { animation-delay: -0.32s; }
        .typing-dots span:nth-child(2) { animation-delay: -0.16s; }

        @keyframes typingDots {
            0%, 80%, 100% {
                transform: scale(0);
                opacity: 0.5;
            }
            40% {
                transform: scale(1);
                opacity: 1;
            }
        }

        @media (max-width: 768px) {
            .main-content {
                grid-template-columns: 1fr;
            }
            
            .sidebar {
                order: 2;
            }
            
            .header-text h1 {
                font-size: 2rem;
            }
            
            .container {
                padding: 10px;
            }
        }

        .model-selector {
            margin-bottom: 20px;
        }

        .model-selector select {
            width: 100%;
            padding: 12px;
            border: 2px solid #e1e5e9;
            border-radius: 12px;
            background: white;
            font-size: 1rem;
            transition: all 0.3s ease;
        }

        .model-selector select:focus {
            outline: none;
            border-color: #667eea;
            box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
        }

        .stats {
            background: linear-gradient(135deg, #f8f9ff, #e8f0fe);
            padding: 15px;
            border-radius: 12px;
            margin-bottom: 20px;
        }

        .stats h4 {
            color: #333;
            margin-bottom: 10px;
        }

        .stat-item {
            display: flex;
            justify-content: space-between;
            margin-bottom: 5px;
            font-size: 0.9rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="cat-avatar">🐱</div>
            <div class="header-text">
                <h1>CatMi</h1>
                <p>Il tuo assistente AI personale con Claude Opus 4</p>
            </div>
            <div class="status">Claude Opus 4 Attivo</div>
        </div>

        <div class="main-content">
            <div class="sidebar">
                <div class="model-selector">
                    <select id="modelSelect">
                        <option value="claude-opus-4">Claude Opus 4 (Intelligenza Massima)</option>
                        <option value="claude-sonnet-4">Claude Sonnet 4 (Bilanciato)</option>
                    </select>
                </div>

                <div class="stats">
                    <h4>📊 Statistiche Sessione</h4>
                    <div class="stat-item">
                        <span>Messaggi inviati:</span>
                        <span id="messageCount">0</span>
                    </div>
                    <div class="stat-item">
                        <span>Chat salvate:</span>
                        <span id="chatCount">0</span>
                    </div>
                    <div class="stat-item">
                        <span>Tempo attivo:</span>
                        <span id="activeTime">00:00</span>
                    </div>
                </div>

                <div class="chat-history">
                    <h3>📝 Chat Salvate</h3>
                    <div id="chatList">
                        <div class="chat-item" onclick="loadSampleChat()">
                            <strong>Chat di Benvenuto</strong>
                            <div style="font-size: 0.8rem; opacity: 0.7;">Inizia qui la tua esperienza!</div>
                        </div>
                    </div>
                </div>

                <div class="controls">
                    <button class="btn" onclick="newChat()">🆕 Nuova Chat</button>
                    <button class="btn" onclick="saveChat()">💾 Salva Chat</button>
                    <button class="btn" onclick="exportChat()">📤 Esporta Chat</button>
                    <button class="btn" onclick="clearHistory()">🗑️ Cancella Tutto</button>
                </div>
            </div>

            <div class="chat-container">
                <div class="messages" id="messages">
                    <div class="message ai">
                        <div class="message-content">
                            🐱 Ciao! Sono CatMi, il tuo assistente AI potenziato da Claude Opus 4! Sono qui per aiutarti con qualsiasi cosa tu abbia bisogno. Puoi farmi domande, chiedermi di scrivere codice, aiutarti con la creatività, o semplicemente conversare. Ho una memoria perfetta di tutta la nostra conversazione e posso richiamare qualsiasi informazione precedente. Cosa posso fare per te oggi?
                        </div>
                    </div>
                </div>

                <div class="typing-indicator" id="typingIndicator">
                    🐱 CatMi sta pensando
                    <div class="typing-dots">
                        <span></span>
                        <span></span>
                        <span></span>
                    </div>
                </div>

                <div class="input-container">
                    <div class="input-wrapper">
                        <textarea id="messageInput" 
                                placeholder="Scrivi il tuo messaggio qui... (Premi Ctrl+Invio per inviare)"
                                rows="2"></textarea>
                    </div>
                    <button id="sendBtn" onclick="sendMessage()">🚀</button>
                </div>
            </div>
        </div>
    </div>

    <script>
        let chatHistory = [];
        let savedChats = JSON.parse(localStorage.getItem('catmi_chats') || '[]');
        let currentChatIndex = 0;
        let messageCount = 0;
        let startTime = Date.now();
        let activeTimeInterval;

        // Inizializza l'app
        document.addEventListener('DOMContentLoaded', function() {
            updateChatList();
            updateStats();
            startActiveTimer();
            
            // Aggiungi listener per Ctrl+Enter
            document.getElementById('messageInput').addEventListener('keydown', function(e) {
                if (e.ctrlKey && e.key === 'Enter') {
                    sendMessage();
                }
            });
        });

        function startActiveTimer() {
            activeTimeInterval = setInterval(() => {
                const elapsed = Math.floor((Date.now() - startTime) / 1000);
                const minutes = Math.floor(elapsed / 60);
                const seconds = elapsed % 60;
                document.getElementById('activeTime').textContent = 
                    `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
            }, 1000);
        }

        async function sendMessage() {
            const input = document.getElementById('messageInput');
            const message = input.value.trim();
            
            if (!message) return;

            const model = document.getElementById('modelSelect').value;
            
            // Aggiungi il messaggio dell'utente
            addMessage('user', message);
            input.value = '';
            messageCount++;
            updateStats();

            // Mostra indicatore di digitazione
            showTyping();

            try {
                // Costruisci il contesto della conversazione
                const conversationContext = chatHistory.map(msg => 
                    `${msg.role === 'user' ? 'Umano' : 'CatMi'}: ${msg.content}`
                ).join('\n');

                const fullPrompt = `${conversationContext}\nUmano: ${message}\nCatMi:`;

                // Invia richiesta a Claude tramite Puter.js
                const response = await puter.ai.chat(fullPrompt, {
                    model: model,
                    stream: true
                });

                hideTyping();
                let aiResponse = '';
                let messageDiv = null;

                // Stream della risposta
                for await (const part of response) {
                    if (part?.text) {
                        aiResponse += part.text;
                        
                        if (!messageDiv) {
                            messageDiv = addMessage('ai', '');
                        }
                        
                        messageDiv.innerHTML = formatMessage(aiResponse);
                        scrollToBottom();
                    }
                }

                // Salva nella cronologia
                chatHistory.push({role: 'user', content: message});
                chatHistory.push({role: 'ai', content: aiResponse});

            } catch (error) {
                hideTyping();
                addMessage('ai', `❌ Mi dispiace, si è verificato un errore: ${error.message}. Riprova tra un momento.`);
            }
        }

        function addMessage(role, content) {
            const messagesDiv = document.getElementById('messages');
            const messageDiv = document.createElement('div');
            messageDiv.className = `message ${role}`;
            
            const contentDiv = document.createElement('div');
            contentDiv.className = 'message-content';
            contentDiv.innerHTML = formatMessage(content);
            
            messageDiv.appendChild(contentDiv);
            messagesDiv.appendChild(messageDiv);
            
            scrollToBottom();
            return contentDiv;
        }

        function formatMessage(content) {
            // Formattazione base del testo
            return content
                .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                .replace(/\*(.*?)\*/g, '<em>$1</em>')
                .replace(/```(.*?)```/gs, '<pre style="background:#f4f4f4;padding:10px;border-radius:8px;overflow-x:auto;"><code>$1</code></pre>')
                .replace(/`(.*?)`/g, '<code style="background:#f4f4f4;padding:2px 6px;border-radius:4px;">$1</code>')
                .replace(/\n/g, '<br>');
        }

        function showTyping() {
            document.getElementById('typingIndicator').style.display = 'block';
            scrollToBottom();
        }

        function hideTyping() {
            document.getElementById('typingIndicator').style.display = 'none';
        }

        function scrollToBottom() {
            const messagesDiv = document.getElementById('messages');
            messagesDiv.scrollTop = messagesDiv.scrollHeight;
        }

        function newChat() {
            chatHistory = [];
            document.getElementById('messages').innerHTML = `
                <div class="message ai">
                    <div class="message-content">
                        🐱 Ciao! Sono CatMi, il tuo assistente AI potenziato da Claude Opus 4! Sono pronto per una nuova conversazione. Come posso aiutarti?
                    </div>
                </div>
            `;
        }

        function saveChat() {
            if (chatHistory.length === 0) {
                alert('Non ci sono messaggi da salvare!');
                return;
            }

            const chatName = prompt('Nome per questa chat:', `Chat ${savedChats.length + 1}`);
            if (!chatName) return;

            const newChat = {
                id: Date.now(),
                name: chatName,
                messages: [...chatHistory],
                timestamp: new Date().toLocaleString('it-IT'),
                model: document.getElementById('modelSelect').value
            };

            savedChats.unshift(newChat);
            localStorage.setItem('catmi_chats', JSON.stringify(savedChats));
            updateChatList();
            updateStats();
            
            alert('Chat salvata con successo!');
        }

        function loadChat(chatId) {
            const chat = savedChats.find(c => c.id === chatId);
            if (!chat) return;

            chatHistory = [...chat.messages];
            const messagesDiv = document.getElementById('messages');
            messagesDiv.innerHTML = '';

            chat.messages.forEach(msg => {
                addMessage(msg.role, msg.content);
            });

            // Rimuovi active da tutti gli elementi
            document.querySelectorAll('.chat-item').forEach(item => {
                item.classList.remove('active');
            });
            
            // Aggiungi active all'elemento cliccato
            event.target.closest('.chat-item').classList.add('active');
        }

        function deleteChat(chatId) {
            if (confirm('Sei sicuro di voler eliminare questa chat?')) {
                savedChats = savedChats.filter(c => c.id !== chatId);
                localStorage.setItem('catmi_chats', JSON.stringify(savedChats));
                updateChatList();
                updateStats();
            }
        }

        function updateChatList() {
            const chatList = document.getElementById('chatList');
            
            if (savedChats.length === 0) {
                chatList.innerHTML = `
                    <div class="chat-item" onclick="loadSampleChat()">
                        <strong>Chat di Benvenuto</strong>
                        <div style="font-size: 0.8rem; opacity: 0.7;">Inizia qui la tua esperienza!</div>
                    </div>
                `;
                return;
            }

            chatList.innerHTML = savedChats.map(chat => `
                <div class="chat-item" onclick="loadChat(${chat.id})">
                    <strong>${chat.name}</strong>
                    <div style="font-size: 0.8rem; opacity: 0.7;">${chat.timestamp}</div>
                    <div style="font-size: 0.8rem; opacity: 0.5;">${chat.model}</div>
                    <button onclick="event.stopPropagation(); deleteChat(${chat.id})" 
                            style="float: right; background: #ff4444; color: white; border: none; border-radius: 4px; padding: 2px 6px; font-size: 0.7rem; cursor: pointer;">❌</button>
                </div>
            `).join('');
        }

        function loadSampleChat() {
            newChat();
        }

        function exportChat() {
            if (chatHistory.length === 0) {
                alert('Non ci sono messaggi da esportare!');
                return;
            }

            const exportData = {
                chatName: 'Esportazione CatMi',
                timestamp: new Date().toLocaleString('it-IT'),
                model: document.getElementById('modelSelect').value,
                messages: chatHistory,
                stats: {
                    messageCount: messageCount,
                    duration: document.getElementById('activeTime').textContent
                }
            };

            const blob = new Blob([JSON.stringify(exportData, null, 2)], {
                type: 'application/json'
            });
            
            const url = URL.createObjectURL(blob);
            const a = document.createElement('a');
            a.href = url;
            a.download = `catmi-chat-${Date.now()}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }

        function clearHistory() {
            if (confirm('Sei sicuro di voler cancellare tutta la cronologia? Questa azione non può essere annullata.')) {
                savedChats = [];
                localStorage.setItem('catmi_chats', JSON.stringify(savedChats));
                updateChatList();
                updateStats();
                newChat();
                alert('Cronologia cancellata!');
            }
        }

        function updateStats() {
            document.getElementById('messageCount').textContent = messageCount;
            document.getElementById('chatCount').textContent = savedChats.length;
        }

        // Auto-resize textarea
        document.getElementById('messageInput').addEventListener('input', function() {
            this.style.height = 'auto';
            this.style.height = Math.min(this.scrollHeight, 120) + 'px';
        });
    </script>
</body>
</html>
EOF

print_status "File CatMi creato in $APP_DIR/index.html"

# Set proper permissions
sudo chown -R www-data:www-data $APP_DIR
sudo chmod -R 644 $APP_DIR
sudo chmod 755 $APP_DIR

# Create Nginx configuration
echo -e "${BLUE}⚙️ Configurazione di Nginx...${NC}"
sudo tee $NGINX_CONFIG > /dev/null << EOF
server {
    listen 80;
    server_name $DOMAIN www.$DOMAIN;
    
    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval'; script-src 'self' 'unsafe-inline' 'unsafe-eval' https://js.puter.com; connect-src 'self' https: wss:; img-src 'self' data: https:;" always;

    root $APP_DIR;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # Cache static assets
    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg)\$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;

    # Log files
    access_log /var/log/nginx/catmi_access.log;
    error_log /var/log/nginx/catmi_error.log;
}
EOF

print_status "Configurazione Nginx creata"

# Enable the site
sudo ln -sf $NGINX_CONFIG /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test Nginx configuration
echo -e "${BLUE}🧪 Test configurazione Nginx...${NC}"
if sudo nginx -t; then
    print_status "Configurazione Nginx valida"
    sudo systemctl reload nginx
    print_status "Nginx ricaricato"
else
    print_error "Errore nella configurazione Nginx"
    exit 1
fi

# Install Node.js (opzionale per future estensioni)
echo -e "${BLUE}📦 Installazione di Node.js...${NC}"
if ! command_exists node; then
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    print_status "Node.js installato: $(node --version)"
else
    print_warning "Node.js già installato: $(node --version)"
fi

# Install PM2 per gestione processi (opzionale)
echo -e "${BLUE}🔄 Installazione di PM2...${NC}"
if ! command_exists pm2; then
    sudo npm install -g pm2
    print_status "PM2 installato"
else
    print_warning "PM2 già installato"
fi

# Setup SSL with Let's Encrypt
echo -e "${BLUE}🔐 Configurazione SSL con Let's Encrypt...${NC}"
echo -e "${YELLOW}⚠️ Assicurati che il dominio $DOMAIN punti a questo server prima di continuare!${NC}"
read -p "Il dominio $DOMAIN punta a questo server? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🎯 Ottenimento certificato SSL...${NC}"
    if sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --email $SSL_EMAIL --agree-tos --non-interactive; then
        print_status "Certificato SSL installato con successo!"
        
        # Set up auto-renewal
        sudo systemctl enable certbot.timer
        sudo systemctl start certbot.timer
        print_status "Auto-renewal SSL configurato"
    else
        print_warning "Errore nell'installazione SSL. Puoi configurarlo manualmente in seguito."
    fi
else
    print_warning "SSL saltato. Configura il DNS e poi esegui: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
fi

# Create maintenance scripts
echo -e "${BLUE}🛠️ Creazione script di manutenzione...${NC}"
sudo mkdir -p /opt/catmi

# Create backup script
sudo tee /opt/catmi/backup.sh > /dev/null << 'EOF'
#!/bin/bash
# Backup script per CatMi
BACKUP_DIR="/var/backups/catmi"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR
tar -czf $BACKUP_DIR/catmi_backup_$DATE.tar.gz /var/www/catmi /etc/nginx/sites-available/catmi
find $BACKUP_DIR -name "catmi_backup_*.tar.gz" -mtime +7 -delete

echo "Backup creato: $BACKUP_DIR/catmi_backup_$DATE.tar.gz"
EOF

sudo chmod +x /opt/catmi/backup.sh

# Create update script
sudo tee /opt/catmi/update.sh > /dev/null << 'EOF'
#!/bin/bash
# Update script per CatMi
echo "Aggiornamento sistema..."
apt update && apt upgrade -y

echo "Riavvio servizi..."
systemctl reload nginx
systemctl status nginx --no-pager

echo "Test configurazione Nginx..."
nginx -t

echo "Aggiornamento completato!"
EOF

sudo chmod +x /opt/catmi/update.sh

# Create status script
sudo tee /opt/catmi/status.sh > /dev/null << 'EOF'
#!/bin/bash
# Status script per CatMi
echo "=== Status CatMi ==="
echo "Data: $(date)"
echo ""

echo "🌐 Nginx Status:"
systemctl is-active nginx
systemctl is-enabled nginx
echo ""

echo "🔐 SSL Certificate Status:"
certbot certificates 2>/dev/null | grep -A 3 "catmi.it" || echo "Nessun certificato trovato"
echo ""

echo "💾 Spazio Disco:"
df -h /var/www/catmi
echo ""

echo "📊 Log Nginx (ultime 5 righe):"
tail -5 /var/log/nginx/catmi_access.log 2>/dev/null || echo "Nessun log trovato"
echo ""

echo "🔍 Processo Nginx:"
ps aux | grep nginx | grep -v grep
EOF

sudo chmod +x /opt/catmi/status.sh

# Add cron job for backup
echo -e "${BLUE}⏰ Configurazione backup automatico...${NC}"
(sudo crontab -l 2>/dev/null; echo "0 2 * * * /opt/catmi/backup.sh > /var/log/catmi_backup.log 2>&1") | sudo crontab -
print_status "Backup automatico configurato (ogni giorno alle 2:00 AM)"

# Create log rotation
sudo tee /etc/logrotate.d/catmi > /dev/null << EOF
/var/log/nginx/catmi_*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 640 nginx adm
    sharedscripts
    postrotate
        if [ -f /var/run/nginx.pid ]; then
            kill -USR1 \`cat /var/run/nginx.pid\`
        fi
    endscript
}
EOF

print_status "Log rotation configurato"

# Create systemd service for monitoring (opzionale)
sudo tee /etc/systemd/system/catmi-monitor.service > /dev/null << EOF
[Unit]
Description=CatMi Health Monitor
After=network.target

[Service]
Type=simple
User=www-data
WorkingDirectory=/var/www/catmi
ExecStart=/bin/bash -c 'while true; do sleep 300; /opt/catmi/status.sh >> /var/log/catmi_monitor.log; done'
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable catmi-monitor.service
sudo systemctl start catmi-monitor.service
print_status "Servizio di monitoraggio CatMi avviato"

# Create admin utility
sudo tee /usr/local/bin/catmi > /dev/null << 'EOF'
#!/bin/bash
# CatMi Admin Utility

case "$1" in
    status)
        /opt/catmi/status.sh
        ;;
    backup)
        /opt/catmi/backup.sh
        ;;
    update)
        /opt/catmi/update.sh
        ;;
    logs)
        echo "=== Access Logs ==="
        tail -20 /var/log/nginx/catmi_access.log
        echo ""
        echo "=== Error Logs ==="
        tail -20 /var/log/nginx/catmi_error.log
        ;;
    restart)
        echo "Riavvio servizi CatMi..."
        systemctl reload nginx
        systemctl restart catmi-monitor
        echo "Servizi riavviati!"
        ;;
    *)
        echo "CatMi Admin Utility"
        echo "Uso: catmi {status|backup|update|logs|restart}"
        echo ""
        echo "Comandi disponibili:"
        echo "  status  - Mostra lo status del sistema"
        echo "  backup  - Crea un backup"
        echo "  update  - Aggiorna il sistema"
        echo "  logs    - Mostra i log"
        echo "  restart - Riavvia i servizi"
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/catmi
print_status "Utility admin 'catmi' installata"

# Final security hardening
echo -e "${BLUE}🔒 Hardening sicurezza...${NC}"

# Remove server signature
if ! grep -q "server_tokens off;" /etc/nginx/nginx.conf; then
    sudo sed -i '/http {/a\\tserver_tokens off;' /etc/nginx/nginx.conf
fi

# Add rate limiting
sudo tee /etc/nginx/conf.d/rate-limit.conf > /dev/null << EOF
# Rate limiting configuration
limit_req_zone \$binary_remote_addr zone=api:10m rate=30r/m;
limit_req_zone \$binary_remote_addr zone=login:10m rate=5r/m;
EOF

# Update Nginx main config with rate limiting
sudo sed -i '/server_name.*;/a\\n\t# Rate limiting\n\tlimit_req zone=api burst=10 nodelay;' $NGINX_CONFIG

sudo systemctl reload nginx
print_status "Hardening sicurezza completato"

# Create welcome page with instructions
cat > $APP_DIR/README.md << EOF
# CatMi - Installazione Completata! 🐱

## Informazioni Installazione
- **Data installazione**: $(date)
- **Dominio**: $DOMAIN
- **Directory app**: $APP_DIR
- **Modello AI**: Claude Opus 4
- **SSL**: ${SSL_STATUS:-"Da configurare"}

## Comandi Utili

### Admin Utility
\`\`\`bash
catmi status    # Mostra status sistema
catmi backup    # Crea backup
catmi update    # Aggiorna sistema
catmi logs      # Mostra logs
catmi restart   # Riavvia servizi
\`\`\`

### Gestione Manuale
\`\`\`bash
# Riavvia Nginx
sudo systemctl restart nginx

# Controlla logs
sudo tail -f /var/log/nginx/catmi_access.log
sudo tail -f /var/log/nginx/catmi_error.log

# Backup manuale
sudo /opt/catmi/backup.sh
\`\`\`

## Caratteristiche CatMi
- ✅ Claude Opus 4 integrato
- ✅ Interfaccia moderna e responsive
- ✅ Memoria conversazioni
- ✅ Salvataggio chat
- ✅ Esportazione dati
- ✅ Animazioni fluide
- ✅ SSL ready
- ✅ Backup automatici
- ✅ Monitoraggio sistema

## Prossimi Passi
1. Configura il DNS per puntare $DOMAIN a questo server
2. Esegui: sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN (se non fatto)
3. Visita https://$DOMAIN per usare CatMi!

## Support
Per problemi o domande, controlla i log con: catmi logs
EOF

print_status "Documentazione creata in $APP_DIR/README.md"

# Final system status check
echo -e "${BLUE}🔍 Controllo finale del sistema...${NC}"

# Check services
if systemctl is-active --quiet nginx; then
    print_status "Nginx: Attivo"
else
    print_error "Nginx: Non attivo"
fi

if systemctl is-active --quiet ufw; then
    print_status "Firewall: Attivo"
else
    print_warning "Firewall: Non attivo"
fi

if systemctl is-active --quiet catmi-monitor; then
    print_status "Monitor CatMi: Attivo"
else
    print_warning "Monitor CatMi: Non attivo"
fi

# Check ports
if netstat -tuln | grep -q ":80 "; then
    print_status "Porta 80: Aperta"
else
    print_error "Porta 80: Chiusa"
fi

if netstat -tuln | grep -q ":443 "; then
    print_status "Porta 443: Aperta"
else
    print_warning "Porta 443: Non ancora configurata (normale senza SSL)"
fi

echo ""
echo -e "${GREEN}🎉 ============================================${NC}"
echo -e "${GREEN}🐱 CatMi è stato installato con successo!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo -e "${BLUE}📋 Riepilogo Installazione:${NC}"
echo -e "${BLUE}• Dominio:${NC} $DOMAIN"
echo -e "${BLUE}• Directory:${NC} $APP_DIR"
echo -e "${BLUE}• Modello AI:${NC} Claude Opus 4"
echo -e "${BLUE}• Backup automatici:${NC} Ogni giorno alle 2:00 AM"
echo -e "${BLUE}• Monitoraggio:${NC} Attivo"
echo ""
echo -e "${YELLOW}🔔 Prossimi passi:${NC}"
echo -e "${YELLOW}1.${NC} Configura il DNS per puntare $DOMAIN a questo server IP"
echo -e "${YELLOW}2.${NC} Aspetta la propagazione DNS (può richiedere fino a 24 ore)"
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}3.${NC} Esegui: ${BLUE}sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN${NC}"
fi
echo -e "${YELLOW}4.${NC} Visita https://$DOMAIN per usare CatMi!"
echo ""
echo -e "${GREEN}🛠️ Comandi utili:${NC}"
echo -e "${GREEN}• catmi status${NC}    - Controlla lo stato del sistema"
echo -e "${GREEN}• catmi logs${NC}      - Visualizza i log"
echo -e "${GREEN}• catmi backup${NC}    - Crea un backup manuale"
echo -e "${GREEN}• catmi update${NC}    - Aggiorna il sistema"
echo ""
echo -e "${BLUE}📞 Per supporto tecnico, controlla:${NC}"
echo -e "${BLUE}• Log applicazione:${NC} /var/log/nginx/catmi_*.log"
echo -e "${BLUE}• Documentazione:${NC} $APP_DIR/README.md"
echo ""
echo -e "${GREEN}✨ Grazie per aver scelto CatMi! Buon divertimento! 🐱${NC}"

# Create quick test
echo -e "${BLUE}🧪 Test rapido dell'applicazione...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200"; then
    print_status "CatMi risponde correttamente su localhost"
    echo -e "${GREEN}🌐 Puoi testare l'app visitando: http://$(curl -s ifconfig.me)${NC}"
else
    print_warning "Test localhost fallito - controlla la configurazione"
fi

echo ""
echo -e "${BLUE}📊 Per monitorare il sistema in tempo reale:${NC}"
echo -e "${BLUE}watch -n 5 'catmi status'${NC}"
echo ""

# Save installation info
cat > /opt/catmi/install-info.json << EOF
{
    "installation_date": "$(date -Iseconds)",
    "domain": "$DOMAIN",
    "app_directory": "$APP_DIR",
    "ssl_email": "$SSL_EMAIL",
    "nginx_config": "$NGINX_CONFIG",
    "version": "1.0.0",
    "components": {
        "nginx": "$(nginx -v 2>&1 | cut -d' ' -f3)",
        "certbot": "$(certbot --version 2>&1 | cut -d' ' -f2)",
        "nodejs": "$(node --version 2>/dev/null || echo 'not installed')",
        "pm2": "$(pm2 --version 2>/dev/null || echo 'not installed')"
    }
}
EOF

print_status "Informazioni installazione salvate in /opt/catmi/install-info.json"

# Final instructions
echo ""
echo -e "${YELLOW}🎯 IMPORTANTE: Configurazione DNS${NC}"
echo -e "${YELLOW}Per completare l'installazione, configura i seguenti record DNS:${NC}"
echo ""
echo -e "${BLUE}Record A:${NC}"
echo -e "${BLUE}Nome: @${NC}"
echo -e "${BLUE}Valore: $(curl -s ifconfig.me)${NC}"
echo ""
echo -e "${BLUE}Record A:${NC}"
echo -e "${BLUE}Nome: www${NC}"
echo -e "${BLUE}Valore: $(curl -s ifconfig.me)${NC}"
echo ""
echo -e "${GREEN}🎊 Installazione completata con successo!${NC}"
