/**
 * Performance Dashboard Component
 * Real-time performance monitoring UI for Romanian Septica PWA
 */

class PerformanceDashboard {
    constructor(options = {}) {
        this.options = {
            position: options.position || 'top-right',
            updateInterval: options.updateInterval || 1000,
            showNetworkStats: options.showNetworkStats !== false,
            showRenderStats: options.showRenderStats !== false,
            showMemoryStats: options.showMemoryStats !== false,
            autoHide: options.autoHide !== false,
            minimized: options.minimized || false,
            ...options
        };
        
        this.isVisible = false;
        this.isMinimized = this.options.minimized;
        this.updateTimer = null;
        
        // Performance references
        this.performanceMonitor = null;
        this.wsClient = null;
        this.cardRenderer = null;
        
        this.createElement();
        this.bindEvents();
        
        if (this.options.autoShow) {
            this.show();
        }
    }
    
    /**
     * Create dashboard DOM element
     */
    createElement() {
        this.element = document.createElement('div');
        this.element.className = `performance-dashboard ${this.options.position}`;
        this.element.innerHTML = `
            <div class="dashboard-header">
                <span class="dashboard-title">Performance</span>
                <div class="dashboard-controls">
                    <button class="dashboard-btn minimize-btn" title="Minimize">−</button>
                    <button class="dashboard-btn close-btn" title="Close">×</button>
                </div>
            </div>
            <div class="dashboard-content">
                <div class="metric-group graphics-metrics">
                    <div class="metric-group-title">Graphics</div>
                    <div class="performance-metric" id="fps-metric">
                        <span class="metric-label">FPS:</span>
                        <span class="metric-value">--</span>
                    </div>
                    <div class="performance-metric" id="frame-time-metric">
                        <span class="metric-label">Frame:</span>
                        <span class="metric-value">--ms</span>
                    </div>
                    <div class="performance-metric" id="triangles-metric">
                        <span class="metric-label">Triangles:</span>
                        <span class="metric-value">--</span>
                    </div>
                </div>
                
                <div class="metric-group network-metrics">
                    <div class="metric-group-title">Network</div>
                    <div class="performance-metric" id="latency-metric">
                        <span class="metric-label">Latency:</span>
                        <span class="metric-value">--ms</span>
                    </div>
                    <div class="performance-metric" id="connection-metric">
                        <span class="metric-label">Quality:</span>
                        <span class="metric-value">--</span>
                    </div>
                </div>
                
                <div class="metric-group memory-metrics">
                    <div class="metric-group-title">Memory</div>
                    <div class="performance-metric" id="memory-metric">
                        <span class="metric-label">Used:</span>
                        <span class="metric-value">--MB</span>
                    </div>
                    <div class="performance-metric" id="particles-metric">
                        <span class="metric-label">Particles:</span>
                        <span class="metric-value">--</span>
                    </div>
                </div>
                
                <div class="metric-group device-metrics">
                    <div class="metric-group-title">Device</div>
                    <div class="performance-metric" id="quality-metric">
                        <span class="metric-label">Quality:</span>
                        <span class="metric-value">--</span>
                    </div>
                    <div class="performance-metric" id="device-tier-metric">
                        <span class="metric-label">Tier:</span>
                        <span class="metric-value">--</span>
                    </div>
                </div>
                
                <div class="performance-chart" id="performance-chart">
                    <canvas width="200" height="60"></canvas>
                </div>
            </div>
        `;
        
        // Apply initial state
        if (this.isMinimized) {
            this.element.classList.add('minimized');
        }
        
        document.body.appendChild(this.element);
        
        // Initialize chart
        this.initializeChart();
    }
    
    /**
     * Initialize performance chart
     */
    initializeChart() {
        const canvas = this.element.querySelector('#performance-chart canvas');
        this.chartCtx = canvas.getContext('2d');
        this.chartData = {
            fps: [],
            latency: [],
            memory: []
        };
        this.maxDataPoints = 60; // 1 minute at 1fps
        
        this.drawChart();
    }
    
    /**
     * Draw performance chart
     */
    drawChart() {
        const ctx = this.chartCtx;
        const canvas = ctx.canvas;
        const width = canvas.width;
        const height = canvas.height;
        
        // Clear canvas
        ctx.clearRect(0, 0, width, height);
        
        // Draw background
        ctx.fillStyle = 'rgba(15, 23, 42, 0.8)';
        ctx.fillRect(0, 0, width, height);
        
        // Draw grid
        ctx.strokeStyle = 'rgba(59, 130, 246, 0.2)';
        ctx.lineWidth = 1;
        
        for (let i = 0; i <= 4; i++) {
            const y = (height / 4) * i;
            ctx.beginPath();
            ctx.moveTo(0, y);
            ctx.lineTo(width, y);
            ctx.stroke();
        }
        
        // Draw FPS line
        if (this.chartData.fps.length > 1) {
            ctx.strokeStyle = '#10B981';
            ctx.lineWidth = 2;
            ctx.beginPath();
            
            for (let i = 0; i < this.chartData.fps.length; i++) {
                const x = (width / (this.maxDataPoints - 1)) * i;
                const y = height - (this.chartData.fps[i] / 60) * height;
                
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            }
            ctx.stroke();
        }
        
        // Draw latency line
        if (this.chartData.latency.length > 1) {
            ctx.strokeStyle = '#F59E0B';
            ctx.lineWidth = 1;
            ctx.beginPath();
            
            for (let i = 0; i < this.chartData.latency.length; i++) {
                const x = (width / (this.maxDataPoints - 1)) * i;
                const y = height - (Math.min(this.chartData.latency[i], 200) / 200) * height;
                
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    ctx.lineTo(x, y);
                }
            }
            ctx.stroke();
        }
    }
    
    /**
     * Bind event listeners
     */
    bindEvents() {
        // Minimize/maximize button
        const minimizeBtn = this.element.querySelector('.minimize-btn');
        minimizeBtn.addEventListener('click', () => this.toggleMinimize());
        
        // Close button
        const closeBtn = this.element.querySelector('.close-btn');
        closeBtn.addEventListener('click', () => this.hide());
        
        // Double-click header to minimize/maximize
        const header = this.element.querySelector('.dashboard-header');
        header.addEventListener('dblclick', () => this.toggleMinimize());
        
        // Click outside to hide (if auto-hide enabled)
        if (this.options.autoHide) {
            document.addEventListener('click', (e) => {
                if (!this.element.contains(e.target) && this.isVisible) {
                    this.hide();
                }
            });
        }
    }
    
    /**
     * Set performance monitor references
     */
    setReferences(performanceMonitor, wsClient, cardRenderer) {
        this.performanceMonitor = performanceMonitor;
        this.wsClient = wsClient;
        this.cardRenderer = cardRenderer;
    }
    
    /**
     * Show dashboard
     */
    show() {
        this.isVisible = true;
        this.element.style.display = 'flex';
        this.startUpdating();
    }
    
    /**
     * Hide dashboard
     */
    hide() {
        this.isVisible = false;
        this.element.style.display = 'none';
        this.stopUpdating();
    }
    
    /**
     * Toggle dashboard visibility
     */
    toggle() {
        if (this.isVisible) {
            this.hide();
        } else {
            this.show();
        }
    }
    
    /**
     * Toggle minimize state
     */
    toggleMinimize() {
        this.isMinimized = !this.isMinimized;
        this.element.classList.toggle('minimized', this.isMinimized);
        
        const minimizeBtn = this.element.querySelector('.minimize-btn');
        minimizeBtn.textContent = this.isMinimized ? '+' : '−';
        minimizeBtn.title = this.isMinimized ? 'Maximize' : 'Minimize';
    }
    
    /**
     * Start updating metrics
     */
    startUpdating() {
        if (this.updateTimer) return;
        
        this.updateTimer = setInterval(() => {
            this.updateMetrics();
        }, this.options.updateInterval);
        
        // Initial update
        this.updateMetrics();
    }
    
    /**
     * Stop updating metrics
     */
    stopUpdating() {
        if (this.updateTimer) {
            clearInterval(this.updateTimer);
            this.updateTimer = null;
        }
    }
    
    /**
     * Update all performance metrics
     */
    updateMetrics() {
        if (!this.isVisible) return;
        
        // Update graphics metrics
        this.updateGraphicsMetrics();
        
        // Update network metrics
        this.updateNetworkMetrics();
        
        // Update memory metrics
        this.updateMemoryMetrics();
        
        // Update device metrics
        this.updateDeviceMetrics();
        
        // Update chart
        this.updateChart();
    }
    
    /**
     * Update graphics performance metrics
     */
    updateGraphicsMetrics() {
        if (!this.performanceMonitor) return;
        
        const metrics = this.performanceMonitor.getMetrics();
        
        // FPS
        const fpsElement = this.element.querySelector('#fps-metric .metric-value');
        fpsElement.textContent = Math.round(metrics.averages.fps);
        this.setMetricStatus(fpsElement.parentElement, metrics.averages.fps, 50, 30);
        
        // Frame time
        const frameTimeElement = this.element.querySelector('#frame-time-metric .metric-value');
        frameTimeElement.textContent = `${Math.round(metrics.averages.frameTime)}ms`;
        this.setMetricStatus(frameTimeElement.parentElement, metrics.averages.frameTime, 16, 33, true);
        
        // Triangles (from renderer)
        if (this.cardRenderer) {
            const rendererStats = this.cardRenderer.getStats();
            const trianglesElement = this.element.querySelector('#triangles-metric .metric-value');
            trianglesElement.textContent = this.formatNumber(rendererStats.triangles);
        }
    }
    
    /**
     * Update network performance metrics
     */
    updateNetworkMetrics() {
        if (!this.wsClient) return;
        
        const networkMetrics = this.wsClient.getNetworkMetrics();
        
        // Latency
        const latencyElement = this.element.querySelector('#latency-metric .metric-value');
        latencyElement.textContent = `${networkMetrics.averageLatency}ms`;
        this.setMetricStatus(latencyElement.parentElement, networkMetrics.averageLatency, 50, 100);
        
        // Connection quality
        const connectionElement = this.element.querySelector('#connection-metric .metric-value');
        connectionElement.textContent = networkMetrics.connectionQuality;
        const qualityMap = { excellent: 'good', good: 'good', fair: 'warning', poor: 'error' };
        connectionElement.parentElement.className = `performance-metric ${qualityMap[networkMetrics.connectionQuality] || ''}`;
    }
    
    /**
     * Update memory usage metrics
     */
    updateMemoryMetrics() {
        if (!this.performanceMonitor) return;
        
        const metrics = this.performanceMonitor.getMetrics();
        
        // Memory usage
        const memoryElement = this.element.querySelector('#memory-metric .metric-value');
        memoryElement.textContent = `${metrics.memory}MB`;
        this.setMetricStatus(memoryElement.parentElement, metrics.memory, 100, 200);
        
        // Particle count (from renderer)
        if (this.cardRenderer) {
            const rendererStats = this.cardRenderer.getStats();
            const particlesElement = this.element.querySelector('#particles-metric .metric-value');
            
            if (rendererStats.particles) {
                particlesElement.textContent = `${rendererStats.particles.activeParticles}/${rendererStats.particles.totalParticles}`;
            } else {
                particlesElement.textContent = '0/0';
            }
        }
    }
    
    /**
     * Update device information
     */
    updateDeviceMetrics() {
        if (!this.performanceMonitor) return;
        
        const metrics = this.performanceMonitor.getMetrics();
        
        // Quality level
        const qualityElement = this.element.querySelector('#quality-metric .metric-value');
        qualityElement.textContent = metrics.qualityLevel;
        const qualityColors = { high: 'good', medium: 'warning', low: 'error' };
        qualityElement.parentElement.className = `performance-metric ${qualityColors[metrics.qualityLevel] || ''}`;
        
        // Device tier
        const tierElement = this.element.querySelector('#device-tier-metric .metric-value');
        tierElement.textContent = metrics.deviceTier;
        tierElement.parentElement.className = `performance-metric ${qualityColors[metrics.deviceTier] || ''}`;
    }
    
    /**
     * Update performance chart
     */
    updateChart() {
        if (!this.performanceMonitor) return;
        
        const metrics = this.performanceMonitor.getMetrics();
        
        // Add new data points
        this.chartData.fps.push(metrics.averages.fps);
        this.chartData.memory.push(metrics.memory);
        
        if (this.wsClient) {
            const networkMetrics = this.wsClient.getNetworkMetrics();
            this.chartData.latency.push(networkMetrics.averageLatency);
        }
        
        // Limit data points
        Object.keys(this.chartData).forEach(key => {
            if (this.chartData[key].length > this.maxDataPoints) {
                this.chartData[key].shift();
            }
        });
        
        // Redraw chart
        this.drawChart();
    }
    
    /**
     * Set metric status based on thresholds
     */
    setMetricStatus(element, value, goodThreshold, badThreshold, inverse = false) {
        element.classList.remove('good', 'warning', 'error');
        
        if (inverse) {
            // Lower is better (like frame time)
            if (value <= goodThreshold) {
                element.classList.add('good');
            } else if (value <= badThreshold) {
                element.classList.add('warning');
            } else {
                element.classList.add('error');
            }
        } else {
            // Higher is better (like FPS)
            if (value >= goodThreshold) {
                element.classList.add('good');
            } else if (value >= badThreshold) {
                element.classList.add('warning');
            } else {
                element.classList.add('error');
            }
        }
    }
    
    /**
     * Format large numbers
     */
    formatNumber(num) {
        if (num >= 1000000) {
            return (num / 1000000).toFixed(1) + 'M';
        } else if (num >= 1000) {
            return (num / 1000).toFixed(1) + 'K';
        } else {
            return num.toString();
        }
    }
    
    /**
     * Get current dashboard state
     */
    getState() {
        return {
            visible: this.isVisible,
            minimized: this.isMinimized,
            position: this.options.position
        };
    }
    
    /**
     * Export performance data
     */
    exportData() {
        const data = {
            timestamp: new Date().toISOString(),
            chartData: this.chartData,
            currentMetrics: this.performanceMonitor ? this.performanceMonitor.getMetrics() : null,
            networkMetrics: this.wsClient ? this.wsClient.getNetworkMetrics() : null,
            rendererStats: this.cardRenderer ? this.cardRenderer.getStats() : null
        };
        
        const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = `performance-data-${new Date().toISOString().split('T')[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        
        URL.revokeObjectURL(url);
    }
    
    /**
     * Cleanup dashboard
     */
    destroy() {
        this.stopUpdating();
        this.element.remove();
    }
}

// CSS styles for the dashboard (inject into head)
const dashboardCSS = `
.performance-dashboard {
    position: fixed;
    z-index: 10000;
    background: var(--performance-bg, rgba(15, 23, 42, 0.95));
    border: 1px solid var(--performance-border, rgba(59, 130, 246, 0.3));
    border-radius: 8px;
    backdrop-filter: blur(16px);
    min-width: 250px;
    max-width: 300px;
    font-family: 'JetBrains Mono', monospace;
    font-size: 11px;
    box-shadow: 0 8px 32px rgba(0, 0, 0, 0.3);
    display: none;
    flex-direction: column;
    transition: all 0.3s ease;
}

.performance-dashboard.top-right {
    top: 1rem;
    right: 1rem;
}

.performance-dashboard.top-left {
    top: 1rem;
    left: 1rem;
}

.performance-dashboard.bottom-right {
    bottom: 1rem;
    right: 1rem;
}

.performance-dashboard.bottom-left {
    bottom: 1rem;
    left: 1rem;
}

.performance-dashboard.minimized .dashboard-content {
    display: none;
}

.dashboard-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 8px 12px;
    background: rgba(59, 130, 246, 0.1);
    border-bottom: 1px solid rgba(59, 130, 246, 0.2);
    border-radius: 8px 8px 0 0;
    cursor: move;
}

.dashboard-title {
    font-weight: 600;
    color: var(--text-primary, #F8FAFC);
}

.dashboard-controls {
    display: flex;
    gap: 4px;
}

.dashboard-btn {
    background: none;
    border: none;
    color: var(--text-secondary, #CBD5E1);
    cursor: pointer;
    padding: 2px 6px;
    border-radius: 4px;
    font-family: inherit;
    font-size: 12px;
    transition: background-color 0.2s;
}

.dashboard-btn:hover {
    background: rgba(59, 130, 246, 0.2);
    color: var(--text-primary, #F8FAFC);
}

.dashboard-content {
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 12px;
}

.metric-group {
    display: flex;
    flex-direction: column;
    gap: 4px;
}

.metric-group-title {
    font-size: 10px;
    font-weight: 600;
    color: var(--text-muted, #64748B);
    text-transform: uppercase;
    letter-spacing: 0.5px;
    margin-bottom: 4px;
}

.performance-metric {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 4px 8px;
    background: rgba(255, 255, 255, 0.05);
    border-radius: 4px;
    transition: all 0.2s;
}

.performance-metric.good {
    background: rgba(16, 185, 129, 0.1);
    border-left: 3px solid #10B981;
}

.performance-metric.warning {
    background: rgba(245, 158, 11, 0.1);
    border-left: 3px solid #F59E0B;
}

.performance-metric.error {
    background: rgba(239, 68, 68, 0.1);
    border-left: 3px solid #EF4444;
}

.metric-label {
    color: var(--text-muted, #64748B);
    font-size: 10px;
}

.metric-value {
    color: var(--text-primary, #F8FAFC);
    font-weight: 600;
    font-size: 11px;
}

.performance-chart {
    margin-top: 8px;
    border-radius: 4px;
    overflow: hidden;
    background: rgba(0, 0, 0, 0.2);
}

.performance-chart canvas {
    display: block;
    width: 100%;
    height: 60px;
}

@media (max-width: 768px) {
    .performance-dashboard {
        min-width: 200px;
        max-width: 250px;
        font-size: 10px;
    }
    
    .performance-dashboard.top-right,
    .performance-dashboard.top-left {
        top: 0.5rem;
    }
    
    .performance-dashboard.top-right,
    .performance-dashboard.bottom-right {
        right: 0.5rem;
    }
    
    .performance-dashboard.top-left,
    .performance-dashboard.bottom-left {
        left: 0.5rem;
    }
    
    .dashboard-content {
        padding: 8px;
        gap: 8px;
    }
}
`;

// Inject CSS if not already present
if (!document.querySelector('#performance-dashboard-styles')) {
    const style = document.createElement('style');
    style.id = 'performance-dashboard-styles';
    style.textContent = dashboardCSS;
    document.head.appendChild(style);
}

// Export for global use
window.PerformanceDashboard = PerformanceDashboard;