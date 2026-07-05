/* =============================================
   Sinister H-Town RP Chat — Application Logic
   ============================================= */

(function () {
    'use strict';

    var accentColor = '#BF5700';
    var darkBg = '#0d0d14';
    var fadeTimer = 15;
    var maxMessages = 100;
    var emojiSupport = true;
    var resizable = true;
    var maxLength = 256;
    var chatPrefix = '/';

    var messages = [];
    var messageElements = [];
    var fadeTimers = {};
    var emojiMap = {};
    var commandSuggestions = [];
    var isOpen = false;
    var isFocused = false;
    var currentChannel = 'global';
    var channelPrefix = '';
    var channelLabel = 'Global';
    var channelColor = null;
    var historyIndex = -1;
    var historyBuffer = [];
    var suggestionIndex = -1;
    var activeSuggestions = [];
    var playerName = '';
    var playerJob = {};
    var onlineCount = 0;
    var initReady = false;

    var wrapper = document.getElementById('chat-wrapper');
    var messagesContainer = document.getElementById('messages');
    var messagesInner = document.getElementById('messages-inner');
    var chatInput = document.getElementById('chat-input');
    var inputPrefix = document.getElementById('input-prefix');
    var suggestionsEl = document.getElementById('suggestions');
    var suggestionsList = document.getElementById('suggestions-list');
    var emojiPopup = document.getElementById('emoji-popup');
    var emojiGrid = document.getElementById('emoji-grid');
    var emojiBtn = document.getElementById('emoji-btn');
    var jobSubtabs = document.getElementById('job-subtabs');
    var jobTabsContainer = document.getElementById('job-tabs-container');
    var jobTabsBtn = document.getElementById('job-tabs-btn');
    var resizeHandle = document.getElementById('resize-handle');
    var onlineCountEl = document.getElementById('online-count');
    var channelTabs = document.querySelectorAll('.channel-tab');

    function loadEmojiMap() {
        if (typeof EMOJI_DATA !== 'undefined') {
            emojiMap = EMOJI_DATA;
        } else {
            emojiMap = {
                ':smile:': '\u{1F604}',
                ':grin:': '\u{1F601}',
                ':joy:': '\u{1F602}',
                ':heart:': '\u2764\uFE0F',
                ':fire:': '\u{1F525}',
                ':star:': '\u2B50',
                ':check:': '\u2705',
                ':x:': '\u274C',
                ':warning:': '\u26A0\uFE0F',
                ':car:': '\u{1F697}',
                ':police_car:': '\u{1F694}',
                ':ambulance:': '\u{1F691}',
                ':gun:': '\u{1F52B}',
                ':beer:': '\u{1F37A}',
                ':tada:': '\u{1F389}',
                ':skull:': '\u{1F480}',
                ':100:': '\u{1F4AF}',
                ':thumbsup:': '\u{1F44D}',
                ':thumbsdown:': '\u{1F44E}',
                ':clap:': '\u{1F44F}',
                ':pray:': '\u{1F64F}',
                ':wave:': '\u{1F44B}',
                ':eyes:': '\u{1F440}',
                ':texas:': '\u{1F920}',
                ':cowboy:': '\u{1F920}',
                ':crown:': '\u{1F451}',
                ':money_bag:': '\u{1F4B0}',
                ':lock:': '\u{1F512}',
                ':key:': '\u{1F511}',
                ':phone:': '\u{1F4F1}',
                ':muscle:': '\u{1F4AA}',
                ':trophy:': '\u{1F3C6}',
                ':wrench:': '\u{1F527}',
                ':fish:': '\u{1F41F}',
                ':cactus:': '\u{1F335}',
                ':sunny:': '\u2600\uFE0F',
                ':earth_americas:': '\u{1F30E}',
                ':medal:': '\u{1F3C5}',
                ':hourglass:': '\u23F3',
                ':bulb:': '\u{1F4A1}',
                ':question:': '\u2753',
                ':map:': '\u{1F5FA}\uFE0F',
                ':speech_balloon:': '\u{1F4AC}',
                ':zap:': '\u26A1',
                ':rose:': '\u{1F339}',
                ':broken_heart:': '\u{1F494}',
                ':fireworks:': '\u{1F386}',
            };
        }
    }

    function unescapeEmoji(v) {
        if (emojiSupport && emojiMap[v]) {
            return emojiMap[v];
        }
        return v;
    }

    function parseEmojis(text) {
        if (!emojiSupport || !text) return text;
        return text.replace(/:([\w]+):/g, function (match, name) {
            var key = ':' + name + ':';
            var emoji = unescapeEmoji(key);
            if (emoji !== key) {
                return '<span class="emoji-render">' + emoji + '</span>';
            }
            return match;
        });
    }

    function escapeHtml(text) {
        var map = { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' };
        return String(text).replace(/[&<>"']/g, function (c) { return map[c]; });
    }

    function getTimeString() {
        var d = new Date();
        var h = d.getHours().toString().padStart(2, '0');
        var m = d.getMinutes().toString().padStart(2, '0');
        return h + ':' + m;
    }

    function scrollToBottom() {
        if (messagesContainer) {
            messagesContainer.scrollTop = messagesContainer.scrollHeight;
        }
    }

    function startFadeTimer(msgId) {
        if (fadeTimers[msgId]) {
            clearTimeout(fadeTimers[msgId]);
        }
        fadeTimers[msgId] = setTimeout(function () {
            fadeMessage(msgId);
        }, fadeTimer * 1000);
    }

    function fadeMessage(msgId) {
        var el = document.getElementById('msg-' + msgId);
        if (el) {
            el.classList.add('fading');
            setTimeout(function () {
                if (el) el.classList.add('hidden');
            }, 500);
        }
        if (fadeTimers[msgId]) {
            clearTimeout(fadeTimers[msgId]);
            fadeTimers[msgId] = null;
            delete fadeTimers[msgId];
        }
    }

    function cancelFade(msgId) {
        if (fadeTimers[msgId]) {
            clearTimeout(fadeTimers[msgId]);
            fadeTimers[msgId] = null;
            delete fadeTimers[msgId];
        }
        var el = document.getElementById('msg-' + msgId);
        if (el) {
            el.classList.remove('fading', 'hidden');
        }
    }

    function renderMessage(data) {
        if (!data) return;

        var msgId = data.id || ('m' + Date.now() + Math.random().toString(36).substr(2, 5));
        var type = data.type || 'normal';
        var sender = escapeHtml(data.sender || 'Unknown');
        var message = parseEmojis(escapeHtml(data.message || ''));
        var timestamp = data.timestamp || getTimeString();
        var prefix = data.prefix || '';
        var jobColor = data.color || null;

        var typeClass = 'msg-type-' + type;
        var html = '<div class="chat-message ' + typeClass + '" id="msg-' + msgId + '">';

        html += '<span class="msg-timestamp">' + timestamp + '</span>';

        if (prefix && prefix.length > 0) {
            html += '<span class="msg-prefix" style="color:' + (jobColor || accentColor) + '">' + escapeHtml(prefix) + '</span> ';
        }

        if (type === 'me') {
            html += '<span class="msg-sender" style="color:' + accentColor + '">' + sender + '</span> ';
            html += '<span class="msg-body">' + message + '</span>';
        } else if (type === 'do') {
            html += '<span class="msg-body">' + message + ' (( ' + sender + ' ))</span>';
        } else if (type === 'job') {
            html += '<span class="msg-sender" style="color:' + (jobColor || accentColor) + '">' + sender + '</span>';
            html += '<span class="msg-body">: ' + message + '</span>';
        } else if (type === 'system' || type === 'error' || type === 'auto') {
            html += '<span class="msg-sender">' + sender + '</span> ';
            html += '<span class="msg-body">' + message + '</span>';
        } else {
            html += '<span class="msg-sender">' + sender + '</span>';
            html += '<span class="msg-body">: ' + message + '</span>';
        }

        html += '</div>';

        var temp = document.createElement('div');
        temp.innerHTML = html;
        var el = temp.firstChild;

        messagesInner.appendChild(el);
        messageElements.push({ id: msgId, el: el, data: data });

        if (messages.length > maxMessages) {
            var oldest = messages.shift();
            if (oldest && fadeTimers[oldest.id]) {
                clearTimeout(fadeTimers[oldest.id]);
                delete fadeTimers[oldest.id];
            }
            if (messageElements.length > maxMessages) {
                var oldEl = messageElements.shift();
                if (oldEl && oldEl.el && oldEl.el.parentNode) {
                    oldEl.el.parentNode.removeChild(oldEl.el);
                }
            }
        }

        scrollToBottom();
        startFadeTimer(msgId);

        return msgId;
    }

    function addMessage(data) {
        if (!data) return;
        if (!data.id) {
            data.id = 'm' + Date.now() + Math.random().toString(36).substr(2, 5);
        }
        if (!data.timestamp) {
            data.timestamp = getTimeString();
        }
        messages.push(data);
        if (messages.length > maxMessages) {
            messages.shift();
        }
        renderMessage(data);
    }

    function clearMessages() {
        messages = [];
        messageElements = [];
        Object.keys(fadeTimers).forEach(function (key) {
            clearTimeout(fadeTimers[key]);
        });
        fadeTimers = {};
        messagesInner.innerHTML = '';
    }

    function openChat() {
        isOpen = true;
        wrapper.classList.remove('collapsed');
        cancelAllFades();
        setTimeout(function () {
            chatInput.focus();
            scrollToBottom();
        }, 50);
    }

    function closeChat() {
        isOpen = false;
        historyIndex = -1;
        suggestionIndex = -1;
        activeSuggestions = [];
        hideSuggestions();
        hideEmojiPopup();
        wrapper.classList.add('collapsed');
        chatInput.value = '';
        updatePrefixDisplay();
        fetch('https://cfx-nui-sinister_chat/closeChat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(function () {});
    }

    function cancelAllFades() {
        Object.keys(fadeTimers).forEach(function (key) {
            clearTimeout(fadeTimers[key]);
            delete fadeTimers[key];
        });
        messageElements.forEach(function (item) {
            if (item && item.el) {
                item.el.classList.remove('fading', 'hidden');
            }
        });
    }

    function updatePrefixDisplay() {
        if (channelPrefix && channelPrefix.length > 0) {
            inputPrefix.textContent = channelPrefix;
            inputPrefix.style.color = channelColor || accentColor;
        } else {
            inputPrefix.textContent = '';
        }
        if (currentChannel === 'global') {
            inputPrefix.textContent = '';
        }
    }

    function setChannel(channel, label, prefix, color) {
        currentChannel = channel || 'global';
        channelLabel = label || 'Global';
        channelPrefix = prefix || '';
        channelColor = color || null;
        updatePrefixDisplay();

        channelTabs.forEach(function (tab) {
            var tabChannel = tab.getAttribute('data-channel');
            if (tabChannel === channel || (channel === 'job' && tab.classList.contains('job-tab-trigger'))) {
                tab.classList.add('active');
            } else {
                tab.classList.remove('active');
            }
        });

        var jobSubtabsAll = document.querySelectorAll('.job-subtab');
        jobSubtabsAll.forEach(function (tab) {
            if (tab.getAttribute('data-channel') === channel && channel === 'job') {
                tab.classList.add('active');
            } else {
                tab.classList.remove('active');
            }
        });
    }

    function buildJobTabs(channels) {
        if (!channels || !channels.length) return;
        jobTabsContainer.innerHTML = '';
        channels.forEach(function (chan) {
            var btn = document.createElement('button');
            btn.className = 'job-subtab';
            btn.setAttribute('data-channel', 'job');
            btn.setAttribute('data-job', chan.name);
            btn.setAttribute('data-prefix', '[' + chan.name.toUpperCase() + ']');
            btn.setAttribute('data-color', chan.color);
            btn.setAttribute('data-label', chan.label);
            btn.textContent = chan.label || chan.name;
            btn.addEventListener('click', function () {
                var channel = this.getAttribute('data-channel');
                var prefix = this.getAttribute('data-prefix');
                var color = this.getAttribute('data-color');
                var label = this.getAttribute('data-label');
                setChannel(channel, label, prefix, color);
                chatInput.value = '';
                chatInput.focus();
            });
            jobTabsContainer.appendChild(btn);
        });
    }

    function buildEmojiGrid() {
        if (!emojiSupport) return;
        emojiGrid.innerHTML = '';
        var keys = Object.keys(emojiMap);
        if (keys.length === 0) return;

        var displayKeys = keys.slice(0, 64);
        displayKeys.forEach(function (key) {
            var div = document.createElement('div');
            div.className = 'emoji-item';
            div.textContent = emojiMap[key];
            div.title = key;
            div.addEventListener('click', function () {
                insertEmojiAtCursor(key);
                hideEmojiPopup();
                chatInput.focus();
            });
            emojiGrid.appendChild(div);
        });
    }

    function insertEmojiAtCursor(emojiCode) {
        var input = chatInput;
        var start = input.selectionStart || 0;
        var end = input.selectionEnd || 0;
        var text = input.value;
        input.value = text.substring(0, start) + emojiCode + text.substring(end);
        input.selectionStart = input.selectionEnd = start + emojiCode.length;
        input.focus();
    }

    function showEmojiPopup() {
        if (!emojiSupport) return;
        emojiPopup.classList.remove('hidden');
        hideSuggestions();
    }

    function hideEmojiPopup() {
        emojiPopup.classList.add('hidden');
    }

    function updateSuggestions(input) {
        if (!input || input.length < 1 || input.charAt(0) !== chatPrefix) {
            hideSuggestions();
            return;
        }

        var partial = input.toLowerCase();
        var matches = [];

        commandSuggestions.forEach(function (s) {
            if (s.command && s.command.toLowerCase().indexOf(partial) === 0) {
                matches.push(s);
            }
        });

        if (matches.length === 0) {
            hideSuggestions();
            return;
        }

        activeSuggestions = matches;
        suggestionIndex = -1;
        renderSuggestions();
    }

    function renderSuggestions() {
        suggestionsList.innerHTML = '';
        if (activeSuggestions.length === 0) {
            hideSuggestions();
            return;
        }

        activeSuggestions.forEach(function (s, idx) {
            var div = document.createElement('div');
            div.className = 'suggestion-item';
            div.setAttribute('data-index', idx);
            div.innerHTML = '<span class="suggestion-dot" style="background:' + (s.color || accentColor) + '"></span>' +
                '<span style="color:' + (s.color || accentColor) + '">' + s.command + '</span>' +
                '<span style="color:#999;font-size:11px;margin-left:auto">' + (s.label || '') + '</span>';
            div.addEventListener('click', function () {
                applySuggestion(idx);
            });
            suggestionsList.appendChild(div);
        });

        suggestionsEl.classList.remove('hidden');
    }

    function applySuggestion(index) {
        if (index < 0 || index >= activeSuggestions.length) return;
        var s = activeSuggestions[index];

        if (s.type === 'job') {
            chatInput.value = s.command + ' ';
            setChannel('job', s.label, '[' + s.label.toUpperCase() + ']', s.color);
        } else {
            chatInput.value = s.command + ' ';
        }

        hideSuggestions();
        chatInput.focus();
        chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length);
    }

    function hideSuggestions() {
        suggestionsEl.classList.add('hidden');
        activeSuggestions = [];
        suggestionIndex = -1;
    }

    function sendMessage(text) {
        if (!text || text.trim().length === 0) return;

        historyBuffer.push(text.trim());
        if (historyBuffer.length > 100) historyBuffer.shift();
        historyIndex = -1;

        fetch('https://cfx-nui-sinister_chat/sendMessage', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ message: text.trim() })
        }).catch(function (err) {
            console.error('[sinister_chat] send error:', err);
        });

        chatInput.value = '';
        hideSuggestions();
        updatePrefixDisplay();
    }

    function initResize() {
        if (!resizable || !resizeHandle) return;

        var startX, startY, startWidth, startHeight;

        function onMouseDown(e) {
            e.preventDefault();
            startX = e.clientX;
            startY = e.clientY;
            startWidth = wrapper.offsetWidth;
            startHeight = wrapper.offsetHeight;
            document.addEventListener('mousemove', onMouseMove);
            document.addEventListener('mouseup', onMouseUp);
        }

        function onMouseMove(e) {
            var dx = e.clientX - startX;
            var dy = e.clientY - startY;
            var newW = Math.max(320, Math.min(600, startWidth + dx));
            var newH = Math.max(200, Math.min(window.innerHeight * 0.8, startHeight + dy));
            wrapper.style.width = newW + 'px';
            wrapper.style.maxHeight = newH + 'px';
            wrapper.style.height = newH + 'px';
            scrollToBottom();
        }

        function onMouseUp() {
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
        }

        resizeHandle.addEventListener('mousedown', onMouseDown);
    }

    function bindEvents() {
        channelTabs.forEach(function (tab) {
            tab.addEventListener('click', function () {
                var channel = this.getAttribute('data-channel');
                var prefix = this.getAttribute('data-prefix') || '';
                var label = this.getAttribute('data-label') || '';
                if (channel === 'job') {
                    jobSubtabs.classList.toggle('hidden');
                    return;
                }
                setChannel(channel, label, prefix);
                chatInput.value = '';
                chatInput.focus();
                jobSubtabs.classList.add('hidden');
            });
        });

        if (jobTabsBtn) {
            jobTabsBtn.addEventListener('click', function () {
                jobSubtabs.classList.toggle('hidden');
            });
        }

        chatInput.addEventListener('keydown', function (e) {
            if (e.key === 'Enter') {
                e.preventDefault();
                var text = chatInput.value;
                if (text.trim().length > 0) {
                    if (currentChannel === 'me' || currentChannel === 'do') {
                        var cmdText = chatPrefix + currentChannel + ' ' + text.trim();
                        sendMessage(cmdText);
                    } else if (currentChannel === 'ooc') {
                        sendMessage(chatPrefix + 'ooc ' + text.trim());
                    } else if (currentChannel === 'twt') {
                        sendMessage(chatPrefix + 'twt ' + text.trim());
                    } else if (currentChannel === 'job') {
                        var jobCmd = channelPrefix.replace('[', '').replace(']', '').toLowerCase();
                        sendMessage(chatPrefix + jobCmd + ' ' + text.trim());
                    } else {
                        sendMessage(text);
                    }
                }
                hideSuggestions();
                return;
            }

            if (e.key === 'ArrowUp') {
                e.preventDefault();
                if (activeSuggestions.length > 0) {
                    suggestionIndex = Math.max(0, suggestionIndex - 1);
                    highlightSuggestion();
                } else if (chatInput.value.length === 0 || historyIndex < 0) {
                    if (historyBuffer.length > 0) {
                        if (historyIndex < 0) historyIndex = historyBuffer.length - 1;
                        else historyIndex = Math.max(0, historyIndex - 1);
                    }
                    if (historyIndex >= 0 && historyIndex < historyBuffer.length) {
                        chatInput.value = historyBuffer[historyIndex];
                        chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length);
                    }
                }
                return;
            }

            if (e.key === 'ArrowDown') {
                e.preventDefault();
                if (activeSuggestions.length > 0) {
                    suggestionIndex = Math.min(activeSuggestions.length - 1, suggestionIndex + 1);
                    highlightSuggestion();
                } else if (historyIndex >= 0) {
                    historyIndex++;
                    if (historyIndex >= historyBuffer.length) {
                        historyIndex = -1;
                        chatInput.value = '';
                    } else {
                        chatInput.value = historyBuffer[historyIndex];
                    }
                    chatInput.setSelectionRange(chatInput.value.length, chatInput.value.length);
                }
                return;
            }

            if (e.key === 'Tab') {
                e.preventDefault();
                if (activeSuggestions.length > 0) {
                    if (suggestionIndex < 0) suggestionIndex = 0;
                    else suggestionIndex = (suggestionIndex + 1) % activeSuggestions.length;
                    highlightSuggestion();
                    applySuggestion(suggestionIndex);
                }
                return;
            }

            if (e.key === 'Escape') {
                e.preventDefault();
                hideSuggestions();
                hideEmojiPopup();
                if (chatInput.value === '') {
                    closeChat();
                } else {
                    chatInput.value = '';
                }
                return;
            }

            suggestionIndex = -1;
        });

        chatInput.addEventListener('input', function () {
            var val = chatInput.value;
            updateSuggestions(val);

            if (val.length === 0 || val.charAt(0) !== chatPrefix) {
                if (currentChannel === 'global') {
                    inputPrefix.textContent = '';
                }
            } else {
                var spaceIdx = val.indexOf(' ');
                var cmd = spaceIdx > 0 ? val.substring(0, spaceIdx).toLowerCase() : val.toLowerCase();
                for (var i = 0; i < commandSuggestions.length; i++) {
                    if (commandSuggestions[i].command === cmd) {
                        var label = commandSuggestions[i].label || cmd;
                        inputPrefix.textContent = label;
                        inputPrefix.style.color = commandSuggestions[i].color || accentColor;
                        break;
                    }
                }
            }
        });

        chatInput.addEventListener('focus', function () {
            isFocused = true;
        });

        chatInput.addEventListener('blur', function () {
            isFocused = false;
            setTimeout(function () {
                hideSuggestions();
                hideEmojiPopup();
            }, 200);
        });

        emojiBtn.addEventListener('click', function (e) {
            e.stopPropagation();
            if (emojiPopup.classList.contains('hidden')) {
                showEmojiPopup();
            } else {
                hideEmojiPopup();
            }
        });

        messagesContainer.addEventListener('mouseenter', function () {
            cancelAllFades();
        });

        messagesContainer.addEventListener('mouseleave', function () {
            messageElements.forEach(function (item) {
                if (item && item.id) {
                    startFadeTimer(item.id);
                }
            });
        });

        document.addEventListener('click', function (e) {
            if (!emojiPopup.contains(e.target) && e.target !== emojiBtn) {
                hideEmojiPopup();
            }
            if (!suggestionsEl.contains(e.target) && e.target !== chatInput) {
                hideSuggestions();
            }
            if (!wrapper.contains(e.target) && isOpen) {
                closeChat();
            }
        });
    }

    function highlightSuggestion() {
        var items = suggestionsList.querySelectorAll('.suggestion-item');
        items.forEach(function (item, idx) {
            if (idx === suggestionIndex) {
                item.classList.add('selected');
                item.scrollIntoView({ block: 'nearest' });
            } else {
                item.classList.remove('selected');
            }
        });
    }

    function requestSuggestions() {
        fetch('https://cfx-nui-sinister_chat/getCommandSuggestions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).then(function (resp) {
            return resp.json();
        }).then(function (data) {
            if (data && data.suggestions) {
                commandSuggestions = data.suggestions;
            }
        }).catch(function () {
            commandSuggestions = [];
        });
    }

    window.addEventListener('message', function (event) {
        var data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case 'openChat':
                openChat();
                if (data.history && Array.isArray(data.history)) {
                    messages = [];
                    messageElements = [];
                    messagesInner.innerHTML = '';
                    data.history.forEach(function (msg) {
                        messages.push(msg);
                        if (messages.length > maxMessages) messages.shift();
                        renderMessage(msg);
                    });
                    scrollToBottom();
                }
                if (data.channel) {
                    setChannel(data.channel, data.label, data.prefix);
                }
                break;

            case 'closeChat':
                closeChat();
                break;

            case 'addMessage':
                addMessage(data.data);
                break;

            case 'clearChat':
                clearMessages();
                break;

            case 'setChannel':
                setChannel(data.channel, data.label, data.prefix, data.color);
                break;

            case 'initComplete':
                initReady = true;
                if (data.config) {
                    accentColor = data.config.accentColor || accentColor;
                    darkBg = data.config.darkBg || darkBg;
                    fadeTimer = data.config.fadeTimer || fadeTimer;
                    maxMessages = data.config.maxMessages || maxMessages;
                    emojiSupport = data.config.emojiSupport;
                    resizable = data.config.resizable;
                    maxLength = data.config.maxLength || maxLength;
                    chatPrefix = data.config.prefix || chatPrefix;
                }
                if (data.player) {
                    playerName = data.player.name || '';
                    playerJob = data.player.job || {};
                }
                if (data.channels) {
                    buildJobTabs(data.channels);
                }
                if (data.onlineCount !== undefined) {
                    onlineCount = data.onlineCount;
                    onlineCountEl.textContent = onlineCount + ' online';
                }
                requestSuggestions();
                buildEmojiGrid();
                initResize();
                updatePrefixDisplay();
                break;

            case 'playerLoaded':
                if (data.player) {
                    playerName = data.player.name || playerName;
                    playerJob = data.player.job || playerJob;
                }
                break;

            case 'jobUpdate':
                if (data.job) {
                    playerJob = data.job;
                }
                break;

            case 'updateOnline':
                if (data.count !== undefined) {
                    onlineCount = data.count;
                    onlineCountEl.textContent = onlineCount + ' online';
                }
                break;
        }
    });

    window.addEventListener('load', function () {
        loadEmojiMap();
        bindEvents();
        wrapper.classList.add('collapsed');
        onlineCountEl.textContent = '0 online';
        inputPrefix.textContent = '';

        fetch('https://cfx-nui-sinister_chat/chatReady', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        }).catch(function () {});
    });
})();
