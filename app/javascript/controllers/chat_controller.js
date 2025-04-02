import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["messages", "input", "button"]
  static values = {
    documentId: String
  }

  connect() {
    this.currentAssistantMessage = null
    this.currentEventSource = null
    this.scrollToBottom()
  }

  disconnect() {
    this.cleanupStreaming()
  }

  scrollToBottom() {
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }

  appendMessage(content, role) {
    const messageDiv = document.createElement('div')
    messageDiv.className = `flex ${role === 'user' ? 'justify-end' : 'justify-start'}`
    
    const messageContent = document.createElement('div')
    messageContent.className = `${role === 'user' ? 'bg-blue-100 text-blue-800' : 'bg-gray-100 text-gray-800'} rounded-lg px-4 py-2 max-w-lg`
    
    const messageText = document.createElement('p')
    messageText.className = 'text-sm whitespace-pre-wrap'
    messageText.textContent = content
    
    const timestamp = document.createElement('p')
    timestamp.className = 'text-xs mt-1 text-gray-500'
    timestamp.textContent = new Date().toLocaleString()
    
    messageContent.appendChild(messageText)
    messageContent.appendChild(timestamp)
    messageDiv.appendChild(messageContent)
    this.messagesTarget.appendChild(messageDiv)
    
    this.scrollToBottom()
    return messageContent
  }

  cleanupStreaming() {
    if (this.currentEventSource) {
      this.currentEventSource.close()
      this.currentEventSource = null
    }
    this.buttonTarget.disabled = false
    this.inputTarget.disabled = false
    this.inputTarget.focus()
    this.currentAssistantMessage = null
  }

  startStreaming(prompt) {
    this.cleanupStreaming()

    this.currentEventSource = new EventSource(`/documents/${this.documentIdValue}/chat_responses/${encodeURIComponent(prompt)}`)
    
    this.currentEventSource.onmessage = (event) => {
      const data = JSON.parse(event.data)
      if (!this.currentAssistantMessage) {
        this.currentAssistantMessage = this.appendMessage('', 'assistant')
      }
      this.currentAssistantMessage.querySelector('p').textContent += data.message
      this.scrollToBottom()
    }

    this.currentEventSource.onerror = (error) => {
      console.error('EventSource failed:', error)
      this.cleanupStreaming()
    }

    this.currentEventSource.onclose = () => {
      this.cleanupStreaming()
    }
  }

  sendMessage(event) {
    if (event) {
      event.preventDefault()
    }

    const prompt = this.inputTarget.value.trim()
    if (!prompt) return

    this.buttonTarget.disabled = true
    this.inputTarget.disabled = true
    this.inputTarget.value = ''

    this.appendMessage(prompt, 'user')
    this.startStreaming(prompt)
  }

  handleKeydown(event) {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault()
      this.sendMessage()
    }
  }
} 