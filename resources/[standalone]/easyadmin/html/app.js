/* ============================================================================
   EasyAdmin — Admin Panel Application
   Sinister H-Town RP
   ============================================================================ */

(function() {
    'use strict';

    var state = {
        players: [],
        resources: [],
        bans: [],
        reports: [],
        role: 'user',
        permissions: {},
        activeTab: 'dashboard',
        currentContextPlayer: null,
        polling: null,
        settings: {}
    };

    // =========================================================================
    //  Initialization
    // =========================================================================

    window.addEventListener('DOMContentLoaded', function() {
        document.getElementById('app').style.display = 'flex';
        initNavigation();
        initEventListeners();
        initSearchListeners();
        initBanFormListeners();
        initReportUiListeners();
        initDashboardListeners();
        initSettingsListeners();
    });

    window.addEventListener('message', function(event) {
        var data = event.data;
        if (!data || !data.action) return;

        switch (data.action) {
            case 'open':
                document.getElementById('app').style.display = 'flex';
                break;
            case 'close':
                document.getElementById('app').style.display = 'none';
                break;
            case 'loadData':
                handleLoadData(data);
                break;
            case 'updatePlayers':
                state.players = data.players || [];
                renderPlayers();
                updateDashboardStats();
                break;
            case 'updateResources':
                state.resources = data.resources || [];
                renderResources();
                updateDashboardStats();
                break;
            case 'updateBans':
                state.bans = data.bans || [];
                renderBans();
                updateDashboardStats();
                break;
            case 'updateReports':
                state.reports = data.reports || [];
                renderReports();
                updateDashboardStats();
                break;
            case 'notify':
                showToast(data.message, data.type || 'info');
                break;
            case 'playerInfo':
                handlePlayerInfo(data.info);
                break;
            case 'serverInfo':
                handleServerInfo(data.info);
                break;
            case 'convars':
                handleConvars(data.convars);
                break;
            case 'screenshotResult':
                showScreenshot(data.targetName, data.imageData);
                break;
            case 'settingsSaved':
                showToast('Settings saved.', 'success');
                break;
            case 'openReportUi':
                openReportUi(data.players, data.categories);
                break;
            case 'closeReportUi':
                closeReportUi();
                break;
            case 'copyToClipboard':
                copyToClipboard(data.text);
                break;
            case 'progressBar':
                break;
        }
    });

    // =========================================================================
    //  Data Handlers
    // =========================================================================

    function handleLoadData(data) {
        state.players = data.players || [];
        state.resources = data.resources || [];
        state.role = data.role || 'user';
        state.permissions = data.permissions || {};

        updateRoleDisplay();
        updateAdminOnlyVisibility();

        renderPlayers();
        renderResources();
        updateDashboardStats();

        document.getElementById('app').style.display = 'flex';
        switchTab('dashboard');
    }

    function updateRoleDisplay() {
        var roleDisplay = document.getElementById('user-role-display');
        if (state.role === 'admin') {
            roleDisplay.textContent = 'Administrator';
            roleDisplay.style.color = '#E74C3C';
        } else if (state.role === 'moderator') {
            roleDisplay.textContent = 'Moderator';
            roleDisplay.style.color = '#F39C12';
        } else {
            roleDisplay.textContent = 'User';
            roleDisplay.style.color = '#888';
        }
    }

    function updateAdminOnlyVisibility() {
        var adminElements = document.querySelectorAll('.admin-only');
        var isAdmin = (state.role === 'admin');
        adminElements.forEach(function(el) {
            if (isAdmin) {
                el.classList.remove('hidden');
            } else {
                el.classList.add('hidden');
            }
        });
    }

    function updateDashboardStats() {
        document.getElementById('stat-players').textContent = state.players.length;
        document.getElementById('stat-bans').textContent = state.bans.length;
        document.getElementById('stat-reports').textContent = state.reports.length;
        document.getElementById('stat-resources').textContent = state.resources.length;
        document.getElementById('player-count').textContent = state.players.length;
        document.getElementById('report-count').textContent = state.reports.length;
    }

    // =========================================================================
    //  Navigation
    // =========================================================================

    function initNavigation() {
        var navButtons = document.querySelectorAll('.nav-btn[data-tab]');
        navButtons.forEach(function(btn) {
            btn.addEventListener('click', function() {
                var tab = this.getAttribute('data-tab');
                switchTab(tab);
            });
        });

        document.getElementById('btn-close').addEventListener('click', function() {
            closePanel();
        });
    }

    window.switchTab = function(tab) {
        state.activeTab = tab;
        var navButtons = document.querySelectorAll('.nav-btn[data-tab]');
        navButtons.forEach(function(btn) {
            btn.classList.remove('active');
            if (btn.getAttribute('data-tab') === tab) {
                btn.classList.add('active');
            }
        });

        var tabContents = document.querySelectorAll('.tab-content');
        tabContents.forEach(function(tc) { tc.classList.remove('active'); });
        var targetTab = document.getElementById('tab-' + tab);
        if (targetTab) targetTab.classList.add('active');
    };

    function closePanel() {
        fetch('https://cfx-nui-easyadmin/close', { method: 'POST', body: '{}' });
        document.getElementById('app').style.display = 'none';
    }

    // =========================================================================
    //  Dashboard
    // =========================================================================

    function initDashboardListeners() {
        document.getElementById('btn-refresh-dash').addEventListener('click', function() {
            fetch('https://cfx-nui-easyadmin/refresh', { method: 'POST', body: '{}' });
        });
    }

    window.quickAction = function(action) {
        var targetId = document.getElementById('quick-target-id').value;
        if (!targetId) {
            showToast('Please enter a player ID.', 'warning');
            return;
        }
        var id = parseInt(targetId);
        fetch('https://cfx-nui-easyadmin/' + action, {
            method: 'POST',
            body: JSON.stringify({ targetId: id })
        });
    };

    // =========================================================================
    //  Players Tab
    // =========================================================================

    function renderPlayers() {
        var tbody = document.getElementById('players-table-body');
        var recentList = document.getElementById('recent-players-list');
        if (!tbody) return;

        if (state.players.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6"><div class="empty-state"><div class="empty-icon">&#128100;</div><p>No players online</p></div></td></tr>';
        } else {
            var searchQuery = (document.getElementById('player-search')?.value || '').toLowerCase();
            var filtered = state.players;
            if (searchQuery) {
                filtered = state.players.filter(function(p) {
                    return p.name.toLowerCase().indexOf(searchQuery) !== -1 || String(p.id) === searchQuery;
                });
            }

            tbody.innerHTML = filtered.map(function(p) {
                var statusHtml = '';
                if (p.isFrozen) statusHtml += '<span class="status-dot frozen"></span>Frozen ';
                if (p.isMuted) statusHtml += '<span class="status-dot muted"></span>Muted ';
                if (!p.isFrozen && !p.isMuted) statusHtml = '<span class="status-dot online"></span>Online';

                var roleBadge = '';
                if (p.role === 'admin') roleBadge = '<span class="role-badge admin">Admin</span>';
                else if (p.role === 'moderator') roleBadge = '<span class="role-badge moderator">Mod</span>';
                else roleBadge = '<span class="role-badge user">User</span>';

                return '<tr>' +
                    '<td>' + p.id + '</td>' +
                    '<td>' + escapeHtml(p.name) + '</td>' +
                    '<td>' + (p.ping || 0) + 'ms</td>' +
                    '<td>' + roleBadge + '</td>' +
                    '<td>' + statusHtml + '</td>' +
                    '<td>' + buildPlayerActions(p) + '</td>' +
                    '</tr>';
            }).join('');
        }

        if (recentList) {
            var shown = state.players.slice(0, 10);
            recentList.innerHTML = shown.map(function(p) {
                return '<div class="compact-item">' +
                    '<span>[' + p.id + '] ' + escapeHtml(p.name) + '</span>' +
                    '<span style="color:var(--text-muted);font-size:11px;">' + (p.ping || 0) + 'ms</span>' +
                    '</div>';
            }).join('');
        }
    }

    function buildPlayerActions(player) {
        var btns = '';
        if (state.permissions.canTeleport) {
            btns += '<button class="btn-icon" onclick="playerAction(\'goto\',' + player.id + ')" title="Goto">&#8594;</button>';
            btns += '<button class="btn-icon" onclick="playerAction(\'bring\',' + player.id + ')" title="Bring">&#8592;</button>';
        }
        if (state.permissions.canKick) {
            btns += '<button class="btn-icon" onclick="playerAction(\'kick\',' + player.id + ')" title="Kick" style="color:var(--danger);">&#10005;</button>';
        }
        if (state.permissions.canBan || state.permissions.canPermBan) {
            btns += '<button class="btn-icon" onclick="playerAction(\'ban\',' + player.id + ')" title="Ban" style="color:var(--danger);">&#9940;</button>';
        }
        if (state.permissions.canMute) {
            var muteBtn = player.isMuted
                ? '<button class="btn-icon" onclick="playerAction(\'unmute\',' + player.id + ')" title="Unmute" style="color:var(--success);">&#128266;</button>'
                : '<button class="btn-icon" onclick="playerAction(\'mute\',' + player.id + ')" title="Mute" style="color:var(--warning);">&#128264;</button>';
            btns += muteBtn;
        }
        if (state.permissions.canFreeze) {
            btns += '<button class="btn-icon" onclick="playerAction(\'freeze\',' + player.id + ')" title="Freeze">&#10074;&#10074;</button>';
        }
        if (state.permissions.canSlap) {
            btns += '<button class="btn-icon" onclick="playerAction(\'slap\',' + player.id + ')" title="Slap">&#128074;</button>';
        }
        if (state.permissions.canHeal) {
            btns += '<button class="btn-icon" onclick="playerAction(\'heal\',' + player.id + ')" title="Heal" style="color:var(--success);">&#9829;</button>';
        }
        if (state.permissions.canRevive) {
            btns += '<button class="btn-icon" onclick="playerAction(\'revive\',' + player.id + ')" title="Revive" style="color:var(--info);">&#9851;</button>';
        }
        if (state.permissions.canScreenshot) {
            btns += '<button class="btn-icon" onclick="playerAction(\'screenshot\',' + player.id + ')" title="Screenshot">&#128247;</button>';
        }
        return '<div class="btn-group">' + btns + '</div>';
    }

    window.playerAction = function(action, targetId) {
        switch (action) {
            case 'kick':
                showModal('Kick Player #' + targetId, buildKickForm(targetId));
                break;
            case 'ban':
                showModal('Ban Player #' + targetId, buildBanForm(targetId));
                break;
            case 'mute':
                showModal('Mute Player #' + targetId, buildMuteForm(targetId));
                break;
            case 'unmute':
                fetch('https://cfx-nui-easyadmin/unmute', { method: 'POST', body: JSON.stringify({ targetId: targetId }) });
                break;
            case 'slap':
                showModal('Slap Player #' + targetId, buildSlapForm(targetId));
                break;
            default:
                fetch('https://cfx-nui-easyadmin/' + action, {
                    method: 'POST',
                    body: JSON.stringify({ targetId: targetId })
                });
                break;
        }
    };

    function buildKickForm(targetId) {
        return '<div class="form-group"><label>Reason</label>' +
            '<input type="text" id="modal-kick-reason" class="input" placeholder="Reason for kick..." value="Violation of server rules">' +
            '</div>' +
            '<div class="form-actions" style="margin-top:16px;">' +
            '<button class="btn btn-danger" onclick="executeModalAction(\'kick\',' + targetId + ')">Kick Player</button>' +
            '<button class="btn btn-outline" onclick="closeModal()">Cancel</button>' +
            '</div>';
    }

    function buildBanForm(targetId) {
        return '<div class="form-group"><label>Duration (days, 0 = permanent)</label>' +
            '<input type="number" id="modal-ban-duration" class="input" value="0" min="0">' +
            '</div>' +
            '<div class="form-group"><label>Reason</label>' +
            '<input type="text" id="modal-ban-reason" class="input" placeholder="Reason for ban..." value="Violation of server rules">' +
            '</div>' +
            '<div class="form-actions" style="margin-top:16px;">' +
            '<button class="btn btn-danger" onclick="executeModalAction(\'ban\',' + targetId + ')">Ban Player</button>' +
            '<button class="btn btn-outline" onclick="closeModal()">Cancel</button>' +
            '</div>';
    }

    function buildMuteForm(targetId) {
        return '<div class="form-group"><label>Duration (seconds)</label>' +
            '<input type="number" id="modal-mute-duration" class="input" value="300" min="0">' +
            '</div>' +
            '<div class="form-actions" style="margin-top:16px;">' +
            '<button class="btn btn-warning" onclick="executeModalAction(\'mute\',' + targetId + ')">Mute Player</button>' +
            '<button class="btn btn-outline" onclick="closeModal()">Cancel</button>' +
            '</div>';
    }

    function buildSlapForm(targetId) {
        return '<div class="form-group"><label>Damage (0 = just knockback)</label>' +
            '<input type="number" id="modal-slap-damage" class="input" value="0" min="0">' +
            '</div>' +
            '<div class="form-actions" style="margin-top:16px;">' +
            '<button class="btn btn-warning" onclick="executeModalAction(\'slap\',' + targetId + ')">Slap Player</button>' +
            '<button class="btn btn-outline" onclick="closeModal()">Cancel</button>' +
            '</div>';
    }

    window.executeModalAction = function(action, targetId) {
        var reason, duration, damage;
        switch (action) {
            case 'kick':
                reason = document.getElementById('modal-kick-reason')?.value || 'No reason';
                fetch('https://cfx-nui-easyadmin/confirmAction', {
                    method: 'POST',
                    body: JSON.stringify({ action: 'kick', targetId: targetId, reason: reason })
                });
                break;
            case 'ban':
                duration = document.getElementById('modal-ban-duration')?.value || '0';
                reason = document.getElementById('modal-ban-reason')?.value || 'No reason';
                fetch('https://cfx-nui-easyadmin/confirmAction', {
                    method: 'POST',
                    body: JSON.stringify({ action: 'ban', targetId: targetId, duration: duration, reason: reason })
                });
                break;
            case 'mute':
                duration = document.getElementById('modal-mute-duration')?.value || '300';
                fetch('https://cfx-nui-easyadmin/confirmAction', {
                    method: 'POST',
                    body: JSON.stringify({ action: 'mute', targetId: targetId, duration: duration })
                });
                break;
            case 'slap':
                damage = document.getElementById('modal-slap-damage')?.value || '0';
                fetch('https://cfx-nui-easyadmin/confirmAction', {
                    method: 'POST',
                    body: JSON.stringify({ action: 'slap', targetId: targetId, damage: damage })
                });
                break;
        }
        closeModal();
    };

    // =========================================================================
    //  Bans Tab
    // =========================================================================

    function renderBans() {
        var tbody = document.getElementById('bans-table-body');
        if (!tbody) return;

        if (state.bans.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6"><div class="empty-state"><div class="empty-icon">&#128737;</div><p>No active bans</p></div></td></tr>';
        } else {
            var searchQuery = (document.getElementById('ban-search')?.value || '').toLowerCase();
            var filtered = state.bans;
            if (searchQuery) {
                filtered = state.bans.filter(function(b) {
                    return (b.name && b.name.toLowerCase().indexOf(searchQuery) !== -1) ||
                           String(b.id) === searchQuery;
                });
            }
            tbody.innerHTML = filtered.map(function(b) {
                var durationText = b.duration === 0 ? '<span style="color:var(--danger);">Permanent</span>' : (b.duration + ' days');
                var dateStr = b.createdAt ? new Date(b.createdAt * 1000).toLocaleDateString() : 'N/A';
                return '<tr>' +
                    '<td>#' + b.id + '</td>' +
                    '<td>' + escapeHtml(b.name || 'Unknown') + '</td>' +
                    '<td style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="' + escapeHtml(b.reason || '') + '">' + escapeHtml(b.reason || 'N/A') + '</td>' +
                    '<td>' + durationText + '</td>' +
                    '<td>' + escapeHtml(b.bannedBy || 'Console') + '</td>' +
                    '<td>' + dateStr + '</td>' +
                    '</tr>';
            }).join('');
        }
    }

    function initBanFormListeners() {
        var addBtn = document.getElementById('btn-add-ban');
        var cancelBtn = document.getElementById('btn-cancel-ban');
        var executeBtn = document.getElementById('btn-execute-ban');
        var refreshBtn = document.getElementById('btn-refresh-bans');

        if (addBtn) {
            addBtn.addEventListener('click', function() {
                document.getElementById('add-ban-form').style.display = 'block';
                document.getElementById('ban-player-id').value = '';
                document.getElementById('ban-duration').value = '0';
                document.getElementById('ban-reason').value = '';
            });
        }

        if (cancelBtn) {
            cancelBtn.addEventListener('click', function() {
                document.getElementById('add-ban-form').style.display = 'none';
            });
        }

        if (executeBtn) {
            executeBtn.addEventListener('click', function() {
                var playerId = document.getElementById('ban-player-id').value;
                var duration = document.getElementById('ban-duration').value;
                var reason = document.getElementById('ban-reason').value;
                if (!playerId) {
                    showToast('Please enter a player ID.', 'warning');
                    return;
                }
                fetch('https://cfx-nui-easyadmin/ban', {
                    method: 'POST',
                    body: JSON.stringify({
                        targetId: parseInt(playerId),
                        duration: parseInt(duration) || 0,
                        reason: reason || 'No reason'
                    })
                });
                document.getElementById('add-ban-form').style.display = 'none';
            });
        }

        if (refreshBtn) {
            refreshBtn.addEventListener('click', function() {
                fetch('https://cfx-nui-easyadmin/refresh', { method: 'POST', body: '{}' });
            });
        }
    }

    // =========================================================================
    //  Reports Tab
    // =========================================================================

    function renderReports() {
        var tbody = document.getElementById('reports-table-body');
        if (!tbody) return;

        if (state.reports.length === 0) {
            tbody.innerHTML = '<tr><td colspan="6"><div class="empty-state"><div class="empty-icon">&#128196;</div><p>No pending reports</p></div></td></tr>';
        } else {
            var searchQuery = (document.getElementById('report-search')?.value || '').toLowerCase();
            var filtered = state.reports;
            if (searchQuery) {
                filtered = state.reports.filter(function(r) {
                    return (r.reporterName && r.reporterName.toLowerCase().indexOf(searchQuery) !== -1) ||
                           (r.targetName && r.targetName.toLowerCase().indexOf(searchQuery) !== -1) ||
                           (r.message && r.message.toLowerCase().indexOf(searchQuery) !== -1);
                });
            }
            tbody.innerHTML = filtered.map(function(r) {
                var dateStr = r.createdAt ? new Date(r.createdAt * 1000).toLocaleDateString() : 'N/A';
                return '<tr>' +
                    '<td>#' + r.id + '</td>' +
                    '<td>' + escapeHtml(r.reporterName || 'Unknown') + '</td>' +
                    '<td>' + escapeHtml(r.targetName || 'Unknown') + '</td>' +
                    '<td style="max-width:250px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;" title="' + escapeHtml(r.message || '') + '">' + escapeHtml(r.message || 'N/A') + '</td>' +
                    '<td>' + dateStr + '</td>' +
                    '<td>' +
                    '<button class="btn-icon" onclick="resolveReport(' + r.id + ')" title="Resolve" style="color:var(--success);">&#10003;</button>' +
                    '<button class="btn-icon" onclick="showReportDetail(' + r.id + ')" title="Details" style="color:var(--info);">&#9432;</button>' +
                    '</td>' +
                    '</tr>';
            }).join('');
        }
    }

    window.resolveReport = function(reportId) {
        var resolution = prompt('Resolution note (optional):');
        fetch('https://cfx-nui-easyadmin/resolveReport', {
            method: 'POST',
            body: JSON.stringify({
                reportId: reportId,
                resolution: resolution || 'Resolved'
            })
        });
        showToast('Report #' + reportId + ' resolved.', 'success');
    };

    window.showReportDetail = function(reportId) {
        var report = state.reports.find(function(r) { return r.id === reportId; });
        if (!report) return;
        var content = '<div style="margin-bottom:12px;"><strong>Report #' + report.id + '</strong></div>' +
            '<div class="detail-grid">' +
            '<div class="detail-item"><span class="detail-key">Reporter:</span><span class="detail-value">' + escapeHtml(report.reporterName || 'N/A') + '</span></div>' +
            '<div class="detail-item"><span class="detail-key">Target:</span><span class="detail-value">' + escapeHtml(report.targetName || 'N/A') + '</span></div>' +
            '</div>' +
            '<div style="margin-top:12px;"><strong>Message:</strong></div>' +
            '<div style="background:var(--bg);padding:10px;border-radius:4px;margin-top:4px;">' + escapeHtml(report.message || '') + '</div>';
        showModal('Report Detail', content);
    };

    // =========================================================================
    //  Server Tab
    // =========================================================================

    function renderResources() {
        var tbody = document.getElementById('resources-table-body');
        if (!tbody) return;

        if (state.resources.length === 0) {
            tbody.innerHTML = '<tr><td colspan="3"><div class="empty-state"><p>No resources loaded</p></div></td></tr>';
        } else {
            tbody.innerHTML = state.resources.map(function(r) {
                var tagClass = 'tag-stopped';
                if (r.state === 'started') tagClass = 'tag-started';
                else if (r.state === 'starting') tagClass = 'tag-starting';

                var actions = '';
                if (state.role === 'admin' && !r.isProtected) {
                    if (r.state === 'started') {
                        actions += '<button class="btn-icon" onclick="resourceAction(\'' + r.name + '\',\'restart\')" title="Restart">&#8635;</button>';
                        actions += '<button class="btn-icon" onclick="resourceAction(\'' + r.name + '\',\'stop\')" title="Stop" style="color:var(--danger);">&#9632;</button>';
                    } else {
                        actions += '<button class="btn-icon" onclick="resourceAction(\'' + r.name + '\',\'start\')" title="Start" style="color:var(--success);">&#9654;</button>';
                    }
                } else if (r.isProtected) {
                    actions = '<span style="color:var(--text-muted);font-size:11px;">Protected</span>';
                }

                return '<tr>' +
                    '<td>' + escapeHtml(r.name) + '</td>' +
                    '<td><span class="tag ' + tagClass + '">' + r.state + '</span></td>' +
                    '<td><div class="btn-group">' + actions + '</div></td>' +
                    '</tr>';
            }).join('');
        }
    }

    window.resourceAction = function(resource, action) {
        var confirmed = confirm('Are you sure you want to ' + action + ' resource "' + resource + '"?');
        if (!confirmed) return;
        fetch('https://cfx-nui-easyadmin/resourceAction', {
            method: 'POST',
            body: JSON.stringify({ resource: resource, action: action })
        });
    };

    function handleServerInfo(info) {
        var grid = document.getElementById('server-info-grid');
        if (!grid) return;
        grid.innerHTML =
            '<div class="info-item"><span class="info-label">Server Name</span><span class="info-value">' + escapeHtml(info.name || 'N/A') + '</span></div>' +
            '<div class="info-item"><span class="info-label">Online Players</span><span class="info-value">' + (info.onlinePlayers || 0) + ' / ' + (info.maxPlayers || 32) + '</span></div>' +
            '<div class="info-item"><span class="info-label">Resources</span><span class="info-value">' + (info.resources || 0) + '</span></div>' +
            '<div class="info-item"><span class="info-label">OneSync</span><span class="info-value">' + escapeHtml(info.oneSync || 'off') + '</span></div>' +
            '<div class="info-item"><span class="info-label">Uptime</span><span class="info-value">' + escapeHtml(info.uptime || 'N/A') + '</span></div>' +
            '<div class="info-item"><span class="info-label">Version</span><span class="info-value">' + escapeHtml(info.version || 'N/A') + '</span></div>';
    }

    function handleConvars(convars) {
        var list = document.getElementById('convars-list');
        if (!list || !convars) return;

        list.innerHTML = convars.map(function(c) {
            if (c.sensitive) {
                return '<div class="info-item">' +
                    '<span class="info-label">' + escapeHtml(c.label || c.key) + '</span>' +
                    '<span class="info-value" style="color:var(--text-muted);">***</span>' +
                    '</div>';
            }
            return '<div class="info-item">' +
                '<span class="info-label">' + escapeHtml(c.label || c.key) + '</span>' +
                '<input type="text" class="input" style="width:200px;text-align:right;" value="' + escapeHtml(c.value || '') + '" data-convar-key="' + escapeHtml(c.key) + '" onchange="updateConvar(\'' + escapeHtml(c.key) + '\', this.value)">' +
                '</div>';
        }).join('');
    }

    window.updateConvar = function(key, value) {
        fetch('https://cfx-nui-easyadmin/setConvar', {
            method: 'POST',
            body: JSON.stringify({ key: key, value: value })
        });
        showToast('Convar "' + key + '" updated.', 'success');
    };

    // =========================================================================
    //  Settings Tab
    // =========================================================================

    function initSettingsListeners() {
        var saveBtn = document.getElementById('btn-save-perms');
        if (saveBtn) {
            saveBtn.addEventListener('click', function() {
                var discordId = document.getElementById('perm-discord-id').value.trim();
                var aceGroup = document.getElementById('perm-ace-group').value;
                if (!discordId) {
                    showToast('Please enter a Discord ID.', 'warning');
                    return;
                }
                fetch('https://cfx-nui-easyadmin/editPermissions', {
                    method: 'POST',
                    body: JSON.stringify({ targetDiscord: discordId, aceGroup: aceGroup })
                });
                showToast('Permissions updated for Discord ID: ' + discordId, 'success');
            });
        }
    }

    // =========================================================================
    //  Search Listeners
    // =========================================================================

    function initSearchListeners() {
        var playerSearch = document.getElementById('player-search');
        var banSearch = document.getElementById('ban-search');
        var reportSearch = document.getElementById('report-search');

        if (playerSearch) {
            playerSearch.addEventListener('input', renderPlayers);
        }
        if (banSearch) {
            banSearch.addEventListener('input', renderBans);
        }
        if (reportSearch) {
            reportSearch.addEventListener('input', renderReports);
        }
    }

    // =========================================================================
    //  Modal System
    // =========================================================================

    window.showModal = function(title, bodyContent, footerContent) {
        document.getElementById('modal-title').textContent = title;
        document.getElementById('modal-body').innerHTML = bodyContent || '';
        document.getElementById('modal-footer').innerHTML = footerContent || '';
        document.getElementById('modal-overlay').style.display = 'flex';
    };

    window.closeModal = function() {
        document.getElementById('modal-overlay').style.display = 'none';
    };

    document.getElementById('btn-modal-close').addEventListener('click', closeModal);
    document.getElementById('modal-overlay').addEventListener('click', function(e) {
        if (e.target === this) closeModal();
    });

    // =========================================================================
    //  Screenshot Modal
    // =========================================================================

    function showScreenshot(targetName, imageData) {
        document.getElementById('screenshot-title').textContent = 'Screenshot: ' + (targetName || 'Unknown');
        document.getElementById('screenshot-image').src = imageData || '';
        document.getElementById('screenshot-modal').style.display = 'flex';
    }

    document.getElementById('btn-screenshot-close').addEventListener('click', function() {
        document.getElementById('screenshot-modal').style.display = 'none';
    });

    document.getElementById('screenshot-modal').addEventListener('click', function(e) {
        if (e.target === this) {
            document.getElementById('screenshot-modal').style.display = 'none';
        }
    });

    // =========================================================================
    //  Report UI
    // =========================================================================

    function initReportUiListeners() {
        var submitBtn = document.getElementById('btn-submit-report');
        if (submitBtn) {
            submitBtn.addEventListener('click', function() {
                var targetId = document.getElementById('report-player-select').value;
                var message = document.getElementById('report-message').value;
                var category = document.getElementById('report-category-select').value;
                if (!targetId) {
                    showToast('Please select a player.', 'warning');
                    return;
                }
                if (message.length < 10) {
                    showToast('Message must be at least 10 characters.', 'warning');
                    return;
                }
                fetch('https://cfx-nui-easyadmin/submitReport', {
                    method: 'POST',
                    body: JSON.stringify({
                        targetId: parseInt(targetId),
                        message: message,
                        category: category
                    })
                });
                closeReportUi();
            });
        }

        var reportMsg = document.getElementById('report-message');
        if (reportMsg) {
            reportMsg.addEventListener('input', function() {
                var count = this.value.length;
                document.getElementById('report-char-count').textContent = count + '/500';
            });
        }
    }

    function openReportUi(players, categories) {
        var select = document.getElementById('report-player-select');
        var catSelect = document.getElementById('report-category-select');

        if (select && players) {
            select.innerHTML = '<option value="">-- Select Player --</option>' +
                players.map(function(p) {
                    return '<option value="' + p.id + '">[' + p.id + '] ' + escapeHtml(p.name) + '</option>';
                }).join('');
        }

        if (catSelect && categories) {
            catSelect.innerHTML = categories.map(function(c) {
                return '<option value="' + c + '">' + c + '</option>';
            }).join('');
        }

        document.getElementById('report-ui').style.display = 'flex';
        document.getElementById('report-message').value = '';
        document.getElementById('report-char-count').textContent = '0/500';
    }

    window.closeReportUi = function() {
        document.getElementById('report-ui').style.display = 'none';
        fetch('https://cfx-nui-easyadmin/closeReportUi', { method: 'POST', body: '{}' });
    };

    // =========================================================================
    //  Player Info Handler
    // =========================================================================

    function handlePlayerInfo(info) {
        if (!info) return;
        var content = '<div class="detail-grid">' +
            '<div class="detail-item"><span class="detail-key">Name:</span><span class="detail-value">' + escapeHtml(info.name || 'N/A') + '</span></div>' +
            '<div class="detail-item"><span class="detail-key">ID:</span><span class="detail-value">' + (info.id || 'N/A') + '</span></div>' +
            '<div class="detail-item"><span class="detail-key">Ping:</span><span class="detail-value">' + (info.ping || 0) + 'ms</span></div>' +
            '<div class="detail-item"><span class="detail-key">Health:</span><span class="detail-value">' + (info.health || 0) + '/' + (info.maxHealth || 200) + '</span></div>' +
            '<div class="detail-item"><span class="detail-key">Armor:</span><span class="detail-value">' + (info.armor || 0) + '</span></div>' +
            '<div class="detail-item"><span class="detail-key">Role:</span><span class="detail-value">' + (info.role || 'user') + '</span></div>' +
            '</div>' +
            '<div style="margin-top:12px;"><strong>Identifiers:</strong></div>' +
            '<div class="identifier-list">' + (info.identifiers || []).map(function(id) { return '<div>' + id + '</div>'; }).join('') + '</div>';
        showModal('Player Info: ' + (info.name || 'Unknown'), content);
    }

    // =========================================================================
    //  Toast Notifications
    // =========================================================================

    function showToast(message, type) {
        var container = document.getElementById('toast-container');
        if (!container) return;

        var types = { info: '&#9432;', success: '&#10003;', warning: '&#9888;', error: '&#10005;' };
        var icon = types[type] || types.info;

        // Limit toast count
        var toasts = container.querySelectorAll('.toast');
        if (toasts.length >= 5) {
            toasts[0].remove();
        }

        var toast = document.createElement('div');
        toast.className = 'toast toast-' + type;
        toast.innerHTML =
            '<span class="toast-icon">' + icon + '</span>' +
            '<span class="toast-message">' + escapeHtml(message) + '</span>';

        container.appendChild(toast);

        setTimeout(function() {
            if (toast.parentNode) toast.remove();
        }, 5000);
    }

    // =========================================================================
    //  Refresh Polling
    // =========================================================================

    var refreshInterval = null;

    window.startPolling = function() {
        if (refreshInterval) clearInterval(refreshInterval);
        refreshInterval = setInterval(function() {
            fetch('https://cfx-nui-easyadmin/refresh', { method: 'POST', body: '{}' });
        }, 3000);
    };

    window.stopPolling = function() {
        if (refreshInterval) {
            clearInterval(refreshInterval);
            refreshInterval = null;
        }
    };

    startPolling();

    // =========================================================================
    //  Event Listeners
    // =========================================================================

    function initEventListeners() {
        document.getElementById('btn-refresh-players').addEventListener('click', function() {
            fetch('https://cfx-nui-easyadmin/refresh', { method: 'POST', body: '{}' });
        });
        document.getElementById('btn-refresh-reports').addEventListener('click', function() {
            fetch('https://cfx-nui-easyadmin/refresh', { method: 'POST', body: '{}' });
        });
        document.getElementById('btn-refresh-server').addEventListener('click', function() {
            fetch('https://cfx-nui-easyadmin/getServerInfo', { method: 'POST', body: '{}' });
        });
    }

    // =========================================================================
    //  Keyboard Shortcuts
    // =========================================================================

    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            closeModal();
            document.getElementById('screenshot-modal').style.display = 'none';
        }
    });

    // =========================================================================
    //  Utility Functions
    // =========================================================================

    function escapeHtml(str) {
        if (!str) return '';
        var div = document.createElement('div');
        div.textContent = str;
        return div.innerHTML;
    }

    window.copyToClipboard = function(text) {
        var textarea = document.createElement('textarea');
        textarea.value = text;
        textarea.style.position = 'fixed';
        textarea.style.opacity = '0';
        document.body.appendChild(textarea);
        textarea.select();
        document.execCommand('copy');
        document.body.removeChild(textarea);
        showToast('Copied to clipboard.', 'success');
    };

    // =========================================================================
    //  Export state for debugging
    // =========================================================================

    window.getState = function() { return state; };

})();
