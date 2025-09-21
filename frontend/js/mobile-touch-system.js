/**
 * Enhanced Mobile Touch System for Romanian Septica PWA
 * iOS Safari optimized touch interactions for card gameplay
 */

class MobileTouchSystem {
    constructor(container, card3DRenderer) {
        this.container = container;
        this.card3DRenderer = card3DRenderer;
        
        // Touch state tracking
        this.touches = new Map();
        this.touchStartTime = 0;
        this.touchStartPosition = { x: 0, y: 0 };
        
        // iOS-specific detection
        this.isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent);
        this.isIOSSafari = this.isIOS && /Safari/.test(navigator.userAgent) && !/CriOS|FxiOS/.test(navigator.userAgent);
        
        // Touch thresholds (optimized for iOS)
        this.thresholds = {
            tapTimeout: 300,        // Maximum time for tap
            tapDistance: 15,        // Maximum movement for tap (iOS friendly)
            longPressTime: 500,     // Time for long press
            swipeMinDistance: 30,   // Minimum distance for swipe
            swipeMaxTime: 500,      // Maximum time for swipe
            doubleTapTime: 300      // Time between taps for double tap
        };
        
        // Gesture recognition
        this.lastTapTime = 0;
        this.lastTapTarget = null;
        this.gestureCallbacks = new Map();
        
        // Performance optimizations
        this.touchEventOptions = {
            passive: false,     // Allow preventDefault for iOS
            capture: true
        };
        
        // Initialize touch handling
        this.initializeTouchHandling();
        this.setupIOSOptimizations();
        
        console.log('Mobile Touch System initialized', {
            isIOS: this.isIOS,
            isIOSSafari: this.isIOSSafari,
            thresholds: this.thresholds
        });
    }
    
    /**
     * Initialize touch event handling
     */
    initializeTouchHandling() {
        // Prevent default touch behaviors that interfere with game
        this.container.addEventListener('touchstart', this.handleTouchStart.bind(this), this.touchEventOptions);
        this.container.addEventListener('touchmove', this.handleTouchMove.bind(this), this.touchEventOptions);
        this.container.addEventListener('touchend', this.handleTouchEnd.bind(this), this.touchEventOptions);
        this.container.addEventListener('touchcancel', this.handleTouchCancel.bind(this), this.touchEventOptions);
        
        // Handle mouse events for desktop testing
        this.container.addEventListener('mousedown', this.handleMouseDown.bind(this));
        this.container.addEventListener('mousemove', this.handleMouseMove.bind(this));
        this.container.addEventListener('mouseup', this.handleMouseUp.bind(this));
        
        // Prevent context menu on long press
        this.container.addEventListener('contextmenu', (e) => e.preventDefault());
        
        // Prevent iOS Safari gestures
        if (this.isIOSSafari) {
            this.container.addEventListener('gesturestart', (e) => e.preventDefault());
            this.container.addEventListener('gesturechange', (e) => e.preventDefault());
            this.container.addEventListener('gestureend', (e) => e.preventDefault());
        }
    }
    
    /**
     * Setup iOS-specific optimizations
     */
    setupIOSOptimizations() {
        if (!this.isIOS) return;
        
        // Disable iOS Safari bounce effect
        document.addEventListener('touchmove', (e) => {
            if (e.target.closest('.threejs-container')) {
                e.preventDefault();
            }
        }, { passive: false });
        
        // Prevent iOS zoom on double tap for game area
        let lastTouchEnd = 0;
        this.container.addEventListener('touchend', (e) => {
            const now = (new Date()).getTime();
            if (now - lastTouchEnd <= 300) {
                e.preventDefault();
            }
            lastTouchEnd = now;
        }, false);
        
        // Handle iOS viewport changes
        if (this.isIOSSafari) {
            this.handleIOSViewportChanges();
        }
    }
    
    /**
     * Handle iOS Safari viewport changes (address bar hide/show)
     */
    handleIOSViewportChanges() {
        let initialViewportHeight = window.innerHeight;
        
        const handleViewportChange = () => {
            const currentHeight = window.innerHeight;
            const heightDifference = Math.abs(currentHeight - initialViewportHeight);
            
            // iOS Safari address bar typically changes height by 50-100px
            if (heightDifference > 50) {
                // Resize renderer to match new viewport
                if (this.card3DRenderer && this.card3DRenderer.renderer) {
                    const container = this.card3DRenderer.container;
                    const rect = container.getBoundingClientRect();
                    this.card3DRenderer.renderer.setSize(rect.width, rect.height);
                    this.card3DRenderer.camera.aspect = rect.width / rect.height;
                    this.card3DRenderer.camera.updateProjectionMatrix();
                }
                
                initialViewportHeight = currentHeight;
            }
        };
        
        window.addEventListener('resize', handleViewportChange);
        window.addEventListener('orientationchange', () => {
            setTimeout(handleViewportChange, 500); // Delay for orientation change completion
        });
    }
    
    /**
     * Handle touch start
     */
    handleTouchStart(event) {
        if (!this.shouldHandleTouch(event)) return;
        
        event.preventDefault(); // Critical for iOS Safari
        
        const touch = event.changedTouches[0];
        const touchId = touch.identifier;
        
        const touchData = {
            id: touchId,
            startX: touch.clientX,
            startY: touch.clientY,
            currentX: touch.clientX,
            currentY: touch.clientY,
            startTime: performance.now(),
            target: event.target,
            hasMoved: false
        };
        
        this.touches.set(touchId, touchData);
        
        // Store for gesture recognition
        this.touchStartTime = touchData.startTime;
        this.touchStartPosition = { x: touchData.startX, y: touchData.startY };
        
        // Trigger touch start callbacks
        this.triggerCallback('touchstart', touchData);
    }
    
    /**
     * Handle touch move
     */
    handleTouchMove(event) {
        if (!this.shouldHandleTouch(event)) return;
        
        event.preventDefault(); // Prevent scrolling
        
        for (const touch of event.changedTouches) {
            const touchId = touch.identifier;
            const touchData = this.touches.get(touchId);
            
            if (touchData) {
                const deltaX = Math.abs(touch.clientX - touchData.startX);
                const deltaY = Math.abs(touch.clientY - touchData.startY);
                
                touchData.currentX = touch.clientX;
                touchData.currentY = touch.clientY;
                
                // Mark as moved if beyond threshold
                if (deltaX > this.thresholds.tapDistance || deltaY > this.thresholds.tapDistance) {
                    touchData.hasMoved = true;
                }
                
                // Trigger move callbacks
                this.triggerCallback('touchmove', touchData);
            }
        }
    }
    
    /**
     * Handle touch end
     */
    handleTouchEnd(event) {
        if (!this.shouldHandleTouch(event)) return;
        
        event.preventDefault();
        
        for (const touch of event.changedTouches) {
            const touchId = touch.identifier;
            const touchData = this.touches.get(touchId);
            
            if (touchData) {
                const endTime = performance.now();
                const duration = endTime - touchData.startTime;
                
                touchData.endTime = endTime;
                touchData.duration = duration;
                
                // Determine gesture type
                this.processGesture(touchData);
                
                // Clean up
                this.touches.delete(touchId);
            }
        }
    }
    
    /**
     * Handle touch cancel
     */
    handleTouchCancel(event) {
        for (const touch of event.changedTouches) {
            this.touches.delete(touch.identifier);
        }
    }
    
    /**
     * Process gesture recognition
     */
    processGesture(touchData) {
        const { duration, hasMoved, startX, startY, currentX, currentY } = touchData;
        
        if (!hasMoved && duration < this.thresholds.tapTimeout) {
            // It's a tap
            this.handleTap(touchData);
        } else if (!hasMoved && duration >= this.thresholds.longPressTime) {
            // It's a long press
            this.handleLongPress(touchData);
        } else if (hasMoved && duration < this.thresholds.swipeMaxTime) {
            // Might be a swipe
            const deltaX = currentX - startX;
            const deltaY = currentY - startY;
            const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
            
            if (distance >= this.thresholds.swipeMinDistance) {
                this.handleSwipe(touchData, deltaX, deltaY, distance);
            }
        }
        
        // Trigger end callbacks
        this.triggerCallback('touchend', touchData);
    }
    
    /**
     * Handle tap gesture
     */
    handleTap(touchData) {
        const now = performance.now();
        const isDoubleTap = (now - this.lastTapTime) < this.thresholds.doubleTapTime &&
                           this.lastTapTarget === touchData.target;
        
        if (isDoubleTap) {
            this.handleDoubleTap(touchData);
        } else {
            // Single tap - check for card interaction
            this.handleCardTap(touchData);
        }
        
        this.lastTapTime = now;
        this.lastTapTarget = touchData.target;
    }
    
    /**
     * Handle card tap interaction
     */
    handleCardTap(touchData) {
        if (!this.card3DRenderer) return;
        
        // Use Three.js raycasting to detect card
        const rect = this.container.getBoundingClientRect();
        const x = touchData.startX;
        const y = touchData.startY;
        
        // Convert to normalized device coordinates
        const mouse = new THREE.Vector2();
        mouse.x = ((x - rect.left) / rect.width) * 2 - 1;
        mouse.y = -((y - rect.top) / rect.height) * 2 + 1;
        
        // Raycast
        const raycaster = new THREE.Raycaster();
        raycaster.setFromCamera(mouse, this.card3DRenderer.camera);
        
        if (this.card3DRenderer.scene) {
            const intersects = raycaster.intersectObjects(this.card3DRenderer.scene.children, true);
            
            if (intersects.length > 0) {
                const tappedObject = intersects[0].object;
                
                // Find card parent
                let cardObject = tappedObject;
                while (cardObject && !cardObject.userData.isCard) {
                    cardObject = cardObject.parent;
                }
                
                if (cardObject && cardObject.userData.isCard) {
                    this.handleCardSelected(cardObject, touchData);
                }
            }
        }
        
        // Trigger generic tap callback
        this.triggerCallback('tap', touchData);
    }
    
    /**
     * Handle card selection
     */
    handleCardSelected(cardObject, touchData) {
        console.log('Card selected via touch:', cardObject.userData);
        
        // Add haptic feedback for iOS
        if (this.isIOS && window.navigator.vibrate) {
            window.navigator.vibrate(50); // Light haptic feedback
        }
        
        // Trigger card selection event
        const event = new CustomEvent('cardSelected', {
            detail: {
                card: cardObject.userData,
                touchData: touchData,
                position: {
                    x: cardObject.position.x,
                    y: cardObject.position.y,
                    z: cardObject.position.z
                }
            }
        });
        
        this.container.dispatchEvent(event);
        
        // Visual feedback
        if (this.card3DRenderer.highlightCard) {
            this.card3DRenderer.highlightCard(cardObject);
        }
        
        // Particle effect
        if (this.card3DRenderer.particleEffects) {
            this.card3DRenderer.particleEffects.triggerCardSelect(cardObject.position);
        }
    }
    
    /**
     * Handle double tap
     */
    handleDoubleTap(touchData) {
        console.log('Double tap detected');
        this.triggerCallback('doubletap', touchData);
    }
    
    /**
     * Handle long press
     */
    handleLongPress(touchData) {
        console.log('Long press detected');
        
        // Add haptic feedback for iOS
        if (this.isIOS && window.navigator.vibrate) {
            window.navigator.vibrate([100, 50, 100]); // Pattern for long press
        }
        
        this.triggerCallback('longpress', touchData);
    }
    
    /**
     * Handle swipe gesture
     */
    handleSwipe(touchData, deltaX, deltaY, distance) {
        // Determine swipe direction
        const direction = this.getSwipeDirection(deltaX, deltaY);
        
        console.log('Swipe detected:', direction, distance);
        
        this.triggerCallback('swipe', {
            ...touchData,
            direction,
            deltaX,
            deltaY,
            distance
        });
    }
    
    /**
     * Get swipe direction
     */
    getSwipeDirection(deltaX, deltaY) {
        const absX = Math.abs(deltaX);
        const absY = Math.abs(deltaY);
        
        if (absX > absY) {
            return deltaX > 0 ? 'right' : 'left';
        } else {
            return deltaY > 0 ? 'down' : 'up';
        }
    }
    
    /**
     * Mouse event handlers for desktop testing
     */
    handleMouseDown(event) {
        if (this.isIOS) return; // Only for desktop
        
        const touchData = {
            id: 'mouse',
            startX: event.clientX,
            startY: event.clientY,
            currentX: event.clientX,
            currentY: event.clientY,
            startTime: performance.now(),
            target: event.target,
            hasMoved: false
        };
        
        this.touches.set('mouse', touchData);
        this.triggerCallback('touchstart', touchData);
    }
    
    handleMouseMove(event) {
        if (this.isIOS) return;
        
        const touchData = this.touches.get('mouse');
        if (touchData) {
            const deltaX = Math.abs(event.clientX - touchData.startX);
            const deltaY = Math.abs(event.clientY - touchData.startY);
            
            touchData.currentX = event.clientX;
            touchData.currentY = event.clientY;
            
            if (deltaX > this.thresholds.tapDistance || deltaY > this.thresholds.tapDistance) {
                touchData.hasMoved = true;
            }
            
            this.triggerCallback('touchmove', touchData);
        }
    }
    
    handleMouseUp(event) {
        if (this.isIOS) return;
        
        const touchData = this.touches.get('mouse');
        if (touchData) {
            touchData.endTime = performance.now();
            touchData.duration = touchData.endTime - touchData.startTime;
            
            this.processGesture(touchData);
            this.touches.delete('mouse');
        }
    }
    
    /**
     * Check if touch should be handled
     */
    shouldHandleTouch(event) {
        // Only handle touches on the game container
        return event.target.closest('.threejs-container') !== null;
    }
    
    /**
     * Register gesture callback
     */
    on(gesture, callback) {
        if (!this.gestureCallbacks.has(gesture)) {
            this.gestureCallbacks.set(gesture, []);
        }
        this.gestureCallbacks.get(gesture).push(callback);
    }
    
    /**
     * Remove gesture callback
     */
    off(gesture, callback) {
        const callbacks = this.gestureCallbacks.get(gesture);
        if (callbacks) {
            const index = callbacks.indexOf(callback);
            if (index > -1) {
                callbacks.splice(index, 1);
            }
        }
    }
    
    /**
     * Trigger gesture callback
     */
    triggerCallback(gesture, data) {
        const callbacks = this.gestureCallbacks.get(gesture);
        if (callbacks) {
            callbacks.forEach(callback => {
                try {
                    callback(data);
                } catch (error) {
                    console.error('Touch callback error:', error);
                }
            });
        }
    }
    
    /**
     * Get touch system status
     */
    getStatus() {
        return {
            isIOS: this.isIOS,
            isIOSSafari: this.isIOSSafari,
            activeTouches: this.touches.size,
            thresholds: this.thresholds
        };
    }
    
    /**
     * Destroy touch system
     */
    destroy() {
        // Remove all event listeners
        this.container.removeEventListener('touchstart', this.handleTouchStart);
        this.container.removeEventListener('touchmove', this.handleTouchMove);
        this.container.removeEventListener('touchend', this.handleTouchEnd);
        this.container.removeEventListener('touchcancel', this.handleTouchCancel);
        this.container.removeEventListener('mousedown', this.handleMouseDown);
        this.container.removeEventListener('mousemove', this.handleMouseMove);
        this.container.removeEventListener('mouseup', this.handleMouseUp);
        
        // Clear state
        this.touches.clear();
        this.gestureCallbacks.clear();
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = MobileTouchSystem;
} else if (typeof window !== 'undefined') {
    window.MobileTouchSystem = MobileTouchSystem;
}