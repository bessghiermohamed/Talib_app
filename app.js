/* ============================================
   تطبيق أدبي - المنطق التفاعلي
   الرفيق الأكاديمي لطلاب الأدب العربي
   ============================================ */

(function() {
    'use strict';

    // الشاشة الحالية النشطة
    var currentScreen = 'home';

    /**
     * عرض شاشة معينة وإخفاء الباقي
     * @param {string} screenId - معرف الشاشة (home, courses, schedule, exams, search, profile)
     */
    window.showScreen = function(screenId) {
        // إخفاء جميع الشاشات
        var screens = document.querySelectorAll('.screen');
        screens.forEach(function(screen) {
            screen.classList.remove('active');
        });

        // عرض الشاشة المطلوبة
        var targetScreen = document.getElementById('screen-' + screenId);
        if (targetScreen) {
            targetScreen.classList.add('active');
        }

        // تحديث التنقل السفلي
        updateNavigation(screenId);

        // تحديث الشاشة الحالية
        currentScreen = screenId;

        // التمرير للأعلى
        window.scrollTo({ top: 0, behavior: 'smooth' });
    };

    /**
     * تحديث حالة التنقل السفلي
     * @param {string} screenId - معرف الشاشة النشطة
     */
    function updateNavigation(screenId) {
        var navItems = document.querySelectorAll('.nav-item');
        
        // إزالة الحالة النشطة من جميع العناصر
        navItems.forEach(function(item) {
            item.classList.remove('active');
        });

        // تعريف خريطة التنقل
        var navMap = {
            'home': 0,
            'courses': 1,
            'schedule': 2,
            'exams': 3,
            'profile': 4,
            'search': -1  // البحث لا يظهر في التنقل السفلي
        };

        // تفعيل العنصر الصحيح
        var activeIndex = navMap[screenId];
        if (activeIndex >= 0 && navItems[activeIndex]) {
            navItems[activeIndex].classList.add('active');
        }
    }

    /**
     * تهيئة التبويبات في شاشة المواد
     */
    function initTabs() {
        var tabBtns = document.querySelectorAll('.tab-btn');
        
        tabBtns.forEach(function(btn) {
            btn.addEventListener('click', function() {
                // إزالة الحالة النشطة من جميع التبويبات
                tabBtns.forEach(function(b) {
                    b.classList.remove('active');
                    b.style.background = 'var(--card)';
                    b.style.color = 'var(--muted)';
                });

                // تفعيل التبويب المضغوط عليه
                this.classList.add('active');
                this.style.background = '';
                this.style.color = '';
            });
        });
    }

    /**
     * تهيئة شرائح التصفية في شاشة البحث
     */
    function initFilterChips() {
        var chips = document.querySelectorAll('.chip');
        
        chips.forEach(function(chip) {
            chip.addEventListener('click', function() {
                chips.forEach(function(c) {
                    c.classList.remove('active');
                    c.style.background = 'var(--card)';
                    c.style.color = 'var(--muted)';
                    c.style.borderColor = 'var(--border)';
                });

                this.classList.add('active');
                this.style.background = 'var(--accent-soft)';
                this.style.color = 'var(--accent)';
                this.style.borderColor = 'var(--accent)';
            });
        });
    }

    /**
     * تهيئة أيام الأسبوع في شاشة الجدول
     */
    function initDays() {
        var dayItems = document.querySelectorAll('.day-item');
        
        dayItems.forEach(function(day) {
            day.addEventListener('click', function() {
                dayItems.forEach(function(d) {
                    d.classList.remove('active');
                    d.style.background = 'var(--card)';
                    d.style.color = 'var(--muted)';
                    d.style.borderColor = 'var(--border)';
                });

                this.classList.add('active');
                this.style.background = 'var(--accent)';
                this.style.color = '#0f1e36';
                this.style.borderColor = 'var(--accent)';
            });
        });
    }

    /**
     * تهيئة وظيفة البحث
     */
    function initSearch() {
        var searchInput = document.querySelector('.search-bar input');
        var searchBtn = document.querySelector('.search-btn');

        if (searchInput && searchBtn) {
            searchBtn.addEventListener('click', performSearch);
            
            searchInput.addEventListener('keypress', function(e) {
                if (e.key === 'Enter') {
                    performSearch();
                }
            });
        }
    }

    /**
     * تنفيذ عملية البحث (محاكاة)
     */
    function performSearch() {
        var input = document.querySelector('.search-bar input');
        if (input && input.value.trim()) {
            // محاكاة البحث - في التطبيق الحقيقي سيتم البحث في قاعدة البيانات
            console.log('البحث عن:', input.value);
            
            // إظهار رسالة بسيطة
            var booksGrid = document.querySelector('.books-grid');
            if (booksGrid) {
                booksGrid.style.opacity = '0.5';
                setTimeout(function() {
                    booksGrid.style.opacity = '1';
                }, 500);
            }
        }
    }

    /**
     * تهيئة عناصر الإعدادات
     */
    function initSettings() {
        var settingItems = document.querySelectorAll('.setting-item');
        
        settingItems.forEach(function(item, index) {
            item.addEventListener('click', function() {
                var settingNames = ['تعديل الملف الشخصي', 'الإشعارات', 'المساعدة والدعم'];
                console.log('تم النقر على:', settingNames[index] || 'إعداد');
                
                // تأثير بصري بسيط
                this.style.background = 'rgba(255, 255, 255, 0.05)';
                var self = this;
                setTimeout(function() {
                    self.style.background = '';
                }, 200);
            });
        });
    }

    /**
     * تهيئة بطاقات المواد
     */
    function initCourseCards() {
        var courseCards = document.querySelectorAll('.course-card');
        
        courseCards.forEach(function(card, index) {
            card.addEventListener('click', function() {
                var courseNames = ['النحو والصرف', 'البلاغة', 'الأدب الجاهلي', 'علوم التربية', 'طرق التدريس'];
                console.log('فتح مادة:', courseNames[index] || 'مادة');
                
                // تأثير بصري
                this.style.transform = 'scale(0.98)';
                var self = this;
                setTimeout(function() {
                    self.style.transform = '';
                }, 150);
            });
        });
    }

    /**
     * تهيئة دعم PWA - تسجيل Service Worker (اختياري)
     */
    function initPWA() {
        if ('serviceWorker' in navigator) {
            // يمكن إضافة service worker هنا للدعم الكامل لـ PWA
            console.log('PWA جاهز للتفعيل');
        }
    }

    /**
     * تهيئة التطبيق بالكامل
     */
    function initApp() {
        console.log('تم تحميل تطبيق أدبي بنجاح!');
        console.log('الرفيق الأكاديمي لطلاب الأدب العربي');
        
        initTabs();
        initFilterChips();
        initDays();
        initSearch();
        initSettings();
        initCourseCards();
        initPWA();
    }

    // تشغيل التهيئة عند تحميل الصفحة
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initApp);
    } else {
        initApp();
    }

    // تصدير الدوال للاستخدام الخارجي (اختياري)
    window.AdabiApp = {
        showScreen: showScreen,
        getCurrentScreen: function() { return currentScreen; }
    };

})();
