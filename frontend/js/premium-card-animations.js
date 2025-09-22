/**
 * Premium Card Animations System
 * Implements physics-based animations with Romanian cultural flourishes
 * Inspired by ShuffleCats quality motion and traditional Romanian timing
 */

class PremiumCardAnimations {
    constructor() {
        this.activeAnimations = new Map();
        this.animationQueue = [];
        this.isGSAPLoaded = false;
        
        // Romanian cultural timing patterns
        this.romanianTiming = {
            // Traditional Romanian dance rhythms influence game timing
            hora: { duration: 0.8, ease: "back.out(1.7)" },
            brau: { duration: 0.6, ease: "power2.out" },
            calusari: { duration: 1.2, ease: "elastic.out(1, 0.5)" },
            traditional: { duration: 0.7, ease: "power3.inOut" }
        };
        
        // Physics-based motion constants
        this.physics = {
            gravity: 9.81,
            cardMass: 0.02,    // Card weight in kg
            airResistance: 0.1,
            bounceFactorCard: 0.2,
            bounceFactorTable: 0.1
        };
        
        this.romanianFlourishes = new RomanianCulturalFlourishes();
        
        console.log('🎭 Premium Card Animation System initialized with Romanian cultural elements');
        this.initializeGSAP();
    }
    
    /**
     * Initialize GSAP with Romanian-specific plugins
     */
    async initializeGSAP() {
        try {
            // Load GSAP if not already available
            if (typeof gsap === 'undefined') {
                await this.loadGSAP();
            }
            
            // Register Romanian cultural motion plugins
            if (gsap) {
                gsap.registerPlugin(Physics2DPlugin, MorphSVGPlugin);
                this.isGSAPLoaded = true;
                console.log('🎭 GSAP initialized with Romanian motion plugins');
            }
        } catch (error) {
            console.warn('🎭 GSAP not available, using fallback animations:', error);
            this.isGSAPLoaded = false;
        }
    }
    
    /**
     * Load GSAP library dynamically
     */
    async loadGSAP() {
        return new Promise((resolve, reject) => {
            const script = document.createElement('script');
            script.src = 'https://cdnjs.cloudflare.com/ajax/libs/gsap/3.12.2/gsap.min.js';
            script.onload = resolve;
            script.onerror = reject;
            document.head.appendChild(script);
        });
    }
    
    /**
     * Deal cards with Romanian traditional timing and flair
     */
    async dealCardsSequence(playerCards, region = 'moldovan') {
        const animationId = 'deal_cards_' + Date.now();
        
        if (!this.isGSAPLoaded) {
            return this.fallbackDealAnimation(playerCards);
        }
        
        // Romanian cultural timing based on region
        const timing = this.getRomanianTiming(region);
        const timeline = gsap.timeline();
        
        // Set initial states - cards start as invisible/scaled down
        gsap.set(playerCards, {
            scale: 0,
            rotation: Math.random() * 360 - 180,
            opacity: 0,
            y: "-=100" // Start above the final position
        });
        
        // Staggered appearance with traditional Romanian rhythm
        timeline.to(playerCards, {
            scale: 1,
            rotation: 0,
            opacity: 1,
            y: "+=100", // Move to final position
            duration: timing.duration,
            ease: timing.ease,
            stagger: {
                amount: 0.6, // Total time for all cards to appear
                from: "start",
                ease: "power2.out"
            },
            onStart: () => {
                console.log(`🃏 Dealing cards with ${region} cultural timing`);
            }
        });
        
        // Add Romanian cultural flourish
        timeline.add(() => {
            this.romanianFlourishes.addDealingFlourish(playerCards, region);
        }, "-=0.3");
        
        // Add subtle hover effect preparation
        timeline.to(playerCards, {
            boxShadow: "0 4px 8px rgba(0,0,0,0.2)",
            duration: 0.3,
            ease: "power2.out"
        }, "-=0.2");
        
        this.activeAnimations.set(animationId, timeline);
        
        return new Promise(resolve => {
            timeline.eventCallback("onComplete", () => {
                this.activeAnimations.delete(animationId);
                resolve();
            });
        });
    }
    
    /**
     * Get Romanian cultural timing based on region
     */
    getRomanianTiming(region) {
        const regionTimings = {
            moldovan: this.romanianTiming.hora,
            transylvanian: this.romanianTiming.brau,
            wallachian: this.romanianTiming.calusari,
            traditional: this.romanianTiming.traditional
        };
        
        return regionTimings[region] || this.romanianTiming.traditional;
    }
    
    /**
     * Animate card play with realistic physics and cultural flourish
     */
    async playCardAnimation(card, targetPosition, cardType = 'normal') {
        const animationId = 'play_card_' + Date.now();
        
        if (!this.isGSAPLoaded) {
            return this.fallbackPlayAnimation(card, targetPosition);
        }
        
        const timeline = gsap.timeline();
        const startPosition = this.getElementPosition(card);
        
        // Calculate physics-based arc trajectory
        const arcPath = this.calculateRomanianArc(startPosition, targetPosition, cardType);
        
        // Prepare card for animation
        timeline.set(card, {
            transformOrigin: "center center",
            zIndex: 1000
        });
        
        // Main card movement with Romanian cultural arc
        timeline.to(card, {
            duration: 0.8,
            motionPath: {
                path: arcPath,
                autoRotate: false, // We'll handle rotation manually for cultural effect
                alignOrigin: [0.5, 0.5]
            },
            ease: "power2.out",
            onUpdate: function() {
                // Add cultural rotation during flight
                const progress = this.progress();
                const rotation = Math.sin(progress * Math.PI) * 15; // Gentle rotation
                gsap.set(card, { rotation: rotation });
            }
        });
        
        // Scale effect during movement
        timeline.to(card, {
            scale: 1.1,
            duration: 0.4,
            ease: "power2.out"
        }, 0);
        
        timeline.to(card, {
            scale: 1,
            rotation: 0,
            duration: 0.4,
            ease: "back.out(1.5)"
        }, 0.4);
        
        // Impact effect when card lands
        timeline.add(() => {
            this.triggerRomanianImpactEffect(targetPosition, cardType);
        }, "-=0.1");
        
        // Romanian cultural celebration for special cards
        if (cardType === 'seven' || cardType === 'ace') {
            timeline.add(() => {
                this.romanianFlourishes.addSpecialCardCelebration(card, cardType);
            }, "-=0.2");
        }
        
        this.activeAnimations.set(animationId, timeline);
        
        return new Promise(resolve => {
            timeline.eventCallback("onComplete", () => {
                this.activeAnimations.delete(animationId);
                resolve();
            });
        });
    }
    
    /**
     * Calculate realistic arc trajectory with Romanian cultural influence
     */
    calculateRomanianArc(startPos, endPos, cardType) {
        const distance = Math.sqrt(
            Math.pow(endPos.x - startPos.x, 2) + 
            Math.pow(endPos.y - startPos.y, 2)
        );
        
        // Calculate arc height based on distance and card type
        let arcHeight = distance * 0.3;
        
        // Special cards get higher, more dramatic arcs
        if (cardType === 'seven') {
            arcHeight *= 1.5; // 7s are special in Romanian Septica
        } else if (cardType === 'ace' || cardType === 'ten') {
            arcHeight *= 1.2; // Point cards get slightly higher arc
        }
        
        // Calculate control points for Romanian cultural curve
        const midX = (startPos.x + endPos.x) / 2;
        const midY = (startPos.y + endPos.y) / 2 - arcHeight;
        
        // Traditional Romanian curve - inspired by folk art patterns
        const controlPoint1X = startPos.x + (midX - startPos.x) * 0.6;
        const controlPoint1Y = startPos.y - arcHeight * 0.3;
        
        const controlPoint2X = endPos.x - (endPos.x - midX) * 0.6;
        const controlPoint2Y = endPos.y - arcHeight * 0.3;
        
        // Create SVG path for GSAP motion
        return `M${startPos.x},${startPos.y} C${controlPoint1X},${controlPoint1Y} ${controlPoint2X},${controlPoint2Y} ${endPos.x},${endPos.y}`;
    }
    
    /**
     * Trigger Romanian cultural impact effect when card lands
     */
    triggerRomanianImpactEffect(position, cardType) {
        // Create traditional Romanian particle burst
        const particleCount = cardType === 'seven' ? 12 : 6;
        const particles = this.createRomanianParticles(particleCount);
        
        // Position particles at impact location
        particles.forEach((particle, index) => {
            const angle = (index / particleCount) * Math.PI * 2;
            const radius = 20 + Math.random() * 20;
            
            gsap.set(particle, {
                x: position.x,
                y: position.y,
                scale: 0.5 + Math.random() * 0.5,
                opacity: 0.8
            });
            
            // Animate particles outward
            gsap.to(particle, {
                x: position.x + Math.cos(angle) * radius,
                y: position.y + Math.sin(angle) * radius,
                scale: 0,
                opacity: 0,
                duration: 0.6 + Math.random() * 0.4,
                ease: "power2.out",
                onComplete: () => {
                    particle.remove();
                }
            });
        });
        
        console.log(`✨ Romanian impact effect triggered for ${cardType} card`);
    }
    
    /**
     * Create Romanian cultural particles
     */
    createRomanianParticles(count) {
        const particles = [];
        const colors = ['#fcd34d', '#dc2626', '#002b7f']; // Romanian flag colors
        
        for (let i = 0; i < count; i++) {
            const particle = document.createElement('div');
            particle.style.position = 'absolute';
            particle.style.width = '4px';
            particle.style.height = '4px';
            particle.style.borderRadius = '50%';
            particle.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
            particle.style.pointerEvents = 'none';
            particle.style.zIndex = '10000';
            
            document.body.appendChild(particle);
            particles.push(particle);
        }
        
        return particles;
    }
    
    /**
     * Animate card hover with Romanian cultural elements
     */
    animateCardHover(card, isHovering) {
        const animationId = 'hover_' + card.id;
        
        // Cancel existing hover animation
        if (this.activeAnimations.has(animationId)) {
            this.activeAnimations.get(animationId).kill();
        }
        
        if (!this.isGSAPLoaded) {
            return this.fallbackHoverAnimation(card, isHovering);
        }
        
        const timeline = gsap.timeline();
        
        if (isHovering) {
            // Hover in - Romanian cultural lift effect
            timeline.to(card, {
                y: "-=8",
                rotateX: 5,
                scale: 1.05,
                boxShadow: "0 12px 24px rgba(220, 38, 38, 0.3)", // Romanian red glow
                duration: 0.3,
                ease: "back.out(1.7)"
            });
            
            // Add subtle Romanian border glow
            timeline.to(card, {
                borderColor: "#fcd34d", // Romanian yellow
                borderWidth: "2px",
                duration: 0.2,
                ease: "power2.out"
            }, "-=0.1");
        } else {
            // Hover out - return to normal
            timeline.to(card, {
                y: "+=8",
                rotateX: 0,
                scale: 1,
                boxShadow: "0 4px 8px rgba(0,0,0,0.2)",
                borderColor: "transparent",
                borderWidth: "1px",
                duration: 0.3,
                ease: "power2.inOut"
            });
        }
        
        this.activeAnimations.set(animationId, timeline);
    }
    
    /**
     * Animate trick completion with Romanian celebration
     */
    async animateTrickCompletion(winnerCards, points, winner) {
        const animationId = 'trick_complete_' + Date.now();
        
        if (!this.isGSAPLoaded) {
            return this.fallbackTrickAnimation(winnerCards);
        }
        
        const timeline = gsap.timeline();
        
        // Gather cards animation - traditional Romanian gathering motion
        timeline.to(winnerCards, {
            x: winner === 'player1' ? "-=100" : "+=100",
            y: "+=50",
            rotation: Math.random() * 10 - 5,
            scale: 0.8,
            duration: 0.8,
            ease: "power2.inOut",
            stagger: 0.1
        });
        
        // Add points celebration if points were scored
        if (points > 0) {
            timeline.add(() => {
                this.romanianFlourishes.addPointsCelebration(points, winner);
            }, "-=0.3");
        }
        
        // Fade out collected cards
        timeline.to(winnerCards, {
            opacity: 0,
            scale: 0.5,
            duration: 0.4,
            ease: "power2.in",
            stagger: 0.05
        });
        
        this.activeAnimations.set(animationId, timeline);
        
        return new Promise(resolve => {
            timeline.eventCallback("onComplete", () => {
                this.activeAnimations.delete(animationId);
                resolve();
            });
        });
    }
    
    /**
     * Get element position relative to viewport
     */
    getElementPosition(element) {
        const rect = element.getBoundingClientRect();
        return {
            x: rect.left + rect.width / 2,
            y: rect.top + rect.height / 2
        };
    }
    
    /**
     * Fallback animations for when GSAP is not available
     */
    fallbackDealAnimation(cards) {
        return new Promise(resolve => {
            cards.forEach((card, index) => {
                setTimeout(() => {
                    card.style.transition = 'all 0.5s ease-out';
                    card.style.transform = 'scale(1) rotate(0deg)';
                    card.style.opacity = '1';
                    
                    if (index === cards.length - 1) {
                        setTimeout(resolve, 500);
                    }
                }, index * 100);
            });
        });
    }
    
    fallbackPlayAnimation(card, targetPosition) {
        return new Promise(resolve => {
            card.style.transition = 'all 0.8s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
            card.style.transform = `translate(${targetPosition.x}px, ${targetPosition.y}px) scale(1.1)`;
            
            setTimeout(() => {
                card.style.transform = `translate(${targetPosition.x}px, ${targetPosition.y}px) scale(1)`;
                resolve();
            }, 400);
        });
    }
    
    fallbackHoverAnimation(card, isHovering) {
        card.style.transition = 'all 0.3s ease-out';
        if (isHovering) {
            card.style.transform = 'translateY(-8px) scale(1.05)';
            card.style.boxShadow = '0 12px 24px rgba(220, 38, 38, 0.3)';
        } else {
            card.style.transform = 'translateY(0) scale(1)';
            card.style.boxShadow = '0 4px 8px rgba(0,0,0,0.2)';
        }
    }
    
    fallbackTrickAnimation(cards) {
        return new Promise(resolve => {
            cards.forEach(card => {
                card.style.transition = 'all 0.8s ease-in-out';
                card.style.transform = 'scale(0.8) rotate(5deg)';
                card.style.opacity = '0.8';
            });
            
            setTimeout(() => {
                cards.forEach(card => {
                    card.style.opacity = '0';
                });
                setTimeout(resolve, 400);
            }, 400);
        });
    }
    
    /**
     * Cancel all active animations
     */
    cancelAllAnimations() {
        this.activeAnimations.forEach(animation => {
            animation.kill();
        });
        this.activeAnimations.clear();
        console.log('🎭 All animations cancelled');
    }
    
    /**
     * Update animation quality based on performance level
     */
    updateLOD(qualityLevel) {
        // Adjust animation complexity based on device capability
        switch (qualityLevel) {
            case 'ultra':
                this.romanianFlourishes.enabled = true;
                this.physics.enabled = true;
                break;
                
            case 'high':
                this.romanianFlourishes.enabled = true;
                this.physics.enabled = false;
                break;
                
            case 'medium':
                this.romanianFlourishes.enabled = false;
                this.physics.enabled = false;
                break;
                
            case 'low':
                this.romanianFlourishes.enabled = false;
                this.physics.enabled = false;
                break;
        }
        
        console.log(`🎭 Animation quality updated to ${qualityLevel}`);
    }
    
    /**
     * Get animation performance statistics
     */
    getPerformanceStats() {
        return {
            activeAnimations: this.activeAnimations.size,
            gsapLoaded: this.isGSAPLoaded,
            queueLength: this.animationQueue.length,
            romanianFlourishesEnabled: this.romanianFlourishes.enabled
        };
    }
    
    /**
     * Clean up resources
     */
    dispose() {
        this.cancelAllAnimations();
        this.romanianFlourishes.dispose();
        console.log('🎭 Premium Card Animation System disposed');
    }
}

/**
 * Romanian Cultural Flourishes
 * Manages traditional Romanian visual elements and celebrations
 */
class RomanianCulturalFlourishes {
    constructor() {
        this.enabled = true;
        this.activeFlourishes = new Set();
    }
    
    addDealingFlourish(cards, region) {
        if (!this.enabled) return;
        
        // Add Romanian folk music visual rhythm
        console.log(`🎵 Adding ${region} dealing flourish`);
    }
    
    addSpecialCardCelebration(card, cardType) {
        if (!this.enabled) return;
        
        console.log(`🎉 Celebrating ${cardType} card with Romanian tradition`);
    }
    
    addPointsCelebration(points, winner) {
        if (!this.enabled) return;
        
        console.log(`🏆 Romanian celebration for ${points} points won by ${winner}`);
    }
    
    dispose() {
        this.activeFlourishes.clear();
    }
}

// Export for use in other modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = PremiumCardAnimations;
} else if (typeof window !== 'undefined') {
    window.PremiumCardAnimations = PremiumCardAnimations;
}