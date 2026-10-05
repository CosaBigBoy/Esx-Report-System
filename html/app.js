const app = document.getElementById('app');
const reportsContainer = document.getElementById('reports');
const empty = document.getElementById('empty');
const reportCount = document.getElementById('reportCount');
const closeBtn = document.getElementById('closeBtn');
const reportSound = document.getElementById('reportSound');

let reports = [];

function escapeHtml(value) {
    const div = document.createElement('div');
    div.textContent = value ?? '';
    return div.innerHTML;
}

function openUI(data = {}) {
    app.classList.remove('hidden');

    if (Array.isArray(data.reports)) {
        reports = data.reports;
    }

    renderReports();
}

function closeUI() {
    app.classList.add('hidden');

    fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({})
    });
}

function playReportSound() {
    if (!reportSound) return;

    reportSound.currentTime = 0;

    const promise = reportSound.play();

    if (promise) {
        promise.catch(() => {});
    }
}

function renderReports() {
    reportCount.textContent = reports.length;
    reportsContainer.innerHTML = '';

    if (reports.length === 0) {
        reportsContainer.classList.add('hidden');
        empty.classList.remove('hidden');
        return;
    }

    reportsContainer.classList.remove('hidden');
    empty.classList.add('hidden');

    reports.forEach(report => {
        const element = document.createElement('div');
        element.className = 'report';

        element.innerHTML = `
            <div class="report-id">#${escapeHtml(report.id)}</div>

            <div class="player">
                <div class="player-name">${escapeHtml(report.steamName)}</div>
                <div class="player-id">${escapeHtml(report.createdAt || '')}</div>
            </div>

            <div class="game-id">ID ${escapeHtml(report.gameId)}</div>

            <div class="message">${escapeHtml(report.message)}</div>

            <div class="actions">
                <button class="btn goto" data-action="goto" data-id="${report.id}">
                    GOTO
                </button>

                <button class="btn bring" data-action="bring" data-id="${report.id}">
                    BRING
                </button>

                <button class="btn done" data-action="done" data-id="${report.id}">
                    DONE
                </button>
            </div>
        `;

        reportsContainer.appendChild(element);
    });
}

async function reportAction(action, reportId) {
    try {
        await fetch(`https://${GetParentResourceName()}/action`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                action,
                reportId
            })
        });
    } catch (error) {
        console.error(error);
    }
}

window.addEventListener('message', function(event) {
    const data = event.data;

    if (!data) return;

    if (data.action === 'open') {
        openUI(data);
    }

    if (data.action === 'update') {
        reports = data.reports || [];
        renderReports();
    }

    if (data.action === 'newReportSound') {
        playReportSound();
    }

    if (data.action === 'close') {
        app.classList.add('hidden');
    }
});

reportsContainer.addEventListener('click', function(event) {
    const button = event.target.closest('.btn');

    if (!button) return;

    const action = button.dataset.action;
    const reportId = Number(button.dataset.id);

    if (!action || !reportId) return;

    reportAction(action, reportId);
});

closeBtn.addEventListener('click', closeUI);

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && !app.classList.contains('hidden')) {
        closeUI();
    }
});
