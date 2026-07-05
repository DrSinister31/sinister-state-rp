(function () {
    "use strict";

    let packages = [];
    let categories = [];
    let playerInfo = null;
    let cartItems = {};
    let activeCategory = "all";
    let cartOpen = false;
    let pendingCount = 0;

    const els = {};
    function cacheElements() {
        els.app = document.getElementById("app");
        els.loading = document.getElementById("loadingScreen");
        els.cartPanel = document.getElementById("cartPanel");
        els.cartItems = document.getElementById("cartItems");
        els.cartEmpty = document.getElementById("cartEmpty");
        els.cartTotal = document.getElementById("cartTotal");
        els.cartBadge = document.getElementById("cartBadge");
        els.productGrid = document.getElementById("productGrid");
        els.emptyState = document.getElementById("emptyState");
        els.playerName = document.getElementById("playerName");
        els.playerMoney = document.getElementById("playerMoney");
        els.searchInput = document.getElementById("searchInput");
        els.sortSelect = document.getElementById("sortSelect");
        els.pendingBanner = document.getElementById("pendingBanner");
        els.pendingCountBanner = document.getElementById("pendingCountBanner");
        els.confirmModal = document.getElementById("confirmModal");
        els.confirmDetails = document.getElementById("confirmDetails");
        els.confirmTotal = document.getElementById("confirmTotal");
        els.toastContainer = document.getElementById("toastContainer");
    }

    function showToast(message, type) {
        type = type || "info";
        var toast = document.createElement("div");
        toast.className = "toast toast-" + type;
        toast.textContent = message;
        els.toastContainer.appendChild(toast);
        setTimeout(function () {
            if (toast.parentNode) {
                toast.parentNode.removeChild(toast);
            }
        }, 4000);
    }

    function updateCartCount() {
        var count = Object.keys(cartItems).length;
        if (count > 0) {
            els.cartBadge.textContent = count;
            els.cartBadge.classList.add("show");
        } else {
            els.cartBadge.classList.remove("show");
        }
    }

    function updateCartTotal() {
        var total = 0;
        Object.keys(cartItems).forEach(function (k) {
            total += cartItems[k].price * cartItems[k].quantity;
        });
        els.cartTotal.textContent = STORE_CONFIG.currency + total.toFixed(2);
    }

    function renderCartItems() {
        var keys = Object.keys(cartItems);
        if (keys.length === 0) {
            els.cartEmpty.style.display = "block";
            els.cartItems.querySelectorAll(".cart-item").forEach(function (el) {
                el.remove();
            });
        } else {
            els.cartEmpty.style.display = "none";
            var existing = els.cartItems.querySelectorAll(".cart-item");
            existing.forEach(function (e) { e.remove(); });
            keys.forEach(function (name) {
                var item = cartItems[name];
                var div = document.createElement("div");
                div.className = "cart-item";
                div.innerHTML =
                    '<div class="cart-item-info">' +
                    '<div class="cart-item-name">' + escapeHtml(item.name) + "</div>" +
                    '<div class="cart-item-price">' + STORE_CONFIG.currency + item.price.toFixed(2) + " each</div>" +
                    "</div>" +
                    '<div class="cart-item-actions">' +
                    '<span class="cart-item-qty">x' + item.quantity + "</span>" +
                    '<button class="cart-item-remove" data-item="' + escapeHtml(item.name) + '">&times;</button>' +
                    "</div>";
                div.querySelector(".cart-item-remove").addEventListener("click", function () {
                    removeFromCart(item.name);
                });
                els.cartItems.appendChild(div);
            });
        }
        updateCartCount();
        updateCartTotal();
        var checkoutBtn = document.getElementById("btnCheckout");
        if (checkoutBtn) {
            checkoutBtn.disabled = keys.length === 0;
        }
    }

    function escapeHtml(str) {
        var div = document.createElement("div");
        div.appendChild(document.createTextNode(str));
        return div.innerHTML;
    }

    function addToCart(name, price, category) {
        if (cartItems[name]) {
            cartItems[name].quantity += 1;
        } else {
            cartItems[name] = { name: name, price: price, category: category, quantity: 1 };
        }
        syncCartToClient();
        renderCartItems();
    }

    function removeFromCart(name) {
        delete cartItems[name];
        syncCartToClient();
        renderCartItems();
    }

    function clearCart() {
        cartItems = {};
        syncCartToClient();
        renderCartItems();
    }

    function syncCartToClient() {
        fetch("https://cfx-nui-sinister_store/addToCart", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ action: "sync", cart: cartItems }),
        }).catch(function () {});
    }

    function filterPackages(category) {
        var filtered;
        if (category === "all") {
            filtered = packages.slice();
        } else {
            filtered = packages.filter(function (p) {
                return p.category === category;
            });
        }
        var query = (els.searchInput.value || "").toLowerCase().trim();
        if (query.length > 0) {
            filtered = filtered.filter(function (p) {
                return (
                    p.name.toLowerCase().indexOf(query) !== -1 ||
                    (p.description && p.description.toLowerCase().indexOf(query) !== -1)
                );
            });
        }
        var sort = els.sortSelect.value;
        if (sort === "price-asc") {
            filtered.sort(function (a, b) { return a.price - b.price; });
        } else if (sort === "price-desc") {
            filtered.sort(function (a, b) { return b.price - a.price; });
        } else if (sort === "name-asc") {
            filtered.sort(function (a, b) { return a.name.localeCompare(b.name); });
        } else if (sort === "name-desc") {
            filtered.sort(function (a, b) { return b.name.localeCompare(a.name); });
        }
        return filtered;
    }

    function renderProducts(filtered) {
        if (!filtered) {
            filtered = filterPackages(activeCategory);
        }
        els.productGrid.querySelectorAll(".product-card").forEach(function (el) {
            el.remove();
        });
        if (filtered.length === 0) {
            els.emptyState.style.display = "flex";
            els.emptyState.querySelector("h3").textContent = "No items found";
            els.emptyState.querySelector("p").textContent =
                activeCategory !== "all"
                    ? "This category is empty or no packages match your search."
                    : "Try adjusting your search or check back later.";
        } else {
            els.emptyState.style.display = "none";
            filtered.forEach(function (pkg) {
                var card = createProductCard(pkg);
                els.productGrid.appendChild(card);
            });
        }
    }

    function createProductCard(pkg) {
        var card = document.createElement("div");
        card.className = "product-card";
        var catLabel = getCategoryLabel(pkg.category);
        card.innerHTML =
            '<div class="product-card-image">' + getCategoryIcon(pkg.category) + "</div>" +
            '<div class="product-card-body">' +
            '<div class="product-card-category">' + escapeHtml(catLabel) + "</div>" +
            '<div class="product-card-title">' + escapeHtml(pkg.name) + "</div>" +
            '<div class="product-card-desc">' + escapeHtml(pkg.description || "") + "</div>" +
            "</div>" +
            '<div class="product-card-footer">' +
            '<div class="product-card-price">' + STORE_CONFIG.currency + pkg.price.toFixed(2) + "</div>" +
            '<button class="btn btn-primary btn-sm" data-action="add" data-name="' +
            escapeHtml(pkg.name) +
            '" data-price="' +
            pkg.price +
            '" data-category="' +
            escapeHtml(pkg.category) +
            '">Add to Cart</button>' +
            "</div>";
        card.querySelector("[data-action='add']").addEventListener("click", function () {
            addToCart(pkg.name, pkg.price, pkg.category);
            showToast(pkg.name + " added to cart!", "success");
        });
        return card;
    }

    function getCategoryLabel(id) {
        for (var i = 0; i < categories.length; i++) {
            if (categories[i].id === id) return categories[i].label;
        }
        return id;
    }

    function getCategoryIcon(id) {
        var icons = {
            vip: "\uD83D\uDC51",
            money: "\uD83D\uDCB0",
            vehicles: "\uD83D\uDE97",
            items: "\uD83C\uDF92",
            jobs: "\uD83D\uDCBC",
            gangs: "\uD83D\uDC65",
            customization: "\u270F\uFE0F",
            utilities: "\u2699\uFE0F",
        };
        return icons[id] || "\uD83D\uDCED";
    }

    function buildCategoryNav() {
        var nav = document.querySelector(".category-nav");
        nav.querySelectorAll(".category-btn").forEach(function (b) { b.remove(); });
        var allBtn = document.createElement("button");
        allBtn.className = "category-btn active";
        allBtn.dataset.category = "all";
        allBtn.innerHTML = '<span class="cat-icon">&#9733;</span><span class="cat-label">All Items</span>';
        allBtn.addEventListener("click", function () {
            setActiveCategory("all");
        });
        nav.appendChild(allBtn);
        categories.forEach(function (cat) {
            var btn = document.createElement("button");
            btn.className = "category-btn";
            btn.dataset.category = cat.id;
            btn.innerHTML =
                '<span class="cat-icon">' + getCategoryIcon(cat.id) + '</span><span class="cat-label">' + escapeHtml(cat.label) + "</span>";
            btn.addEventListener("click", function () {
                setActiveCategory(cat.id);
            });
            nav.appendChild(btn);
        });
    }

    function setActiveCategory(catId) {
        activeCategory = catId;
        document.querySelectorAll(".category-btn").forEach(function (btn) {
            btn.classList.toggle("active", btn.dataset.category === catId);
        });
        renderProducts();
    }

    function openCheckoutModal() {
        var keys = Object.keys(cartItems);
        if (keys.length === 0) return;
        var detailsHtml = "";
        var total = 0;
        keys.forEach(function (name) {
            var item = cartItems[name];
            var lineTotal = item.price * item.quantity;
            total += lineTotal;
            detailsHtml +=
                '<div class="confirm-detail-item">' +
                "<span>" +
                escapeHtml(item.name) +
                " x" +
                item.quantity +
                "</span>" +
                "<span>" +
                STORE_CONFIG.currency +
                lineTotal.toFixed(2) +
                "</span>" +
                "</div>";
        });
        els.confirmDetails.innerHTML = detailsHtml;
        els.confirmTotal.textContent = STORE_CONFIG.currency + total.toFixed(2);
        els.confirmModal.classList.add("show");
    }

    function closeModal() {
        els.confirmModal.classList.remove("show");
    }

    function confirmPurchase() {
        var keys = Object.keys(cartItems);
        if (keys.length === 0) {
            showToast("Cart is empty!", "error");
            return;
        }
        fetch("https://cfx-nui-sinister_store/checkout", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ items: cartItems }),
        })
            .then(function (res) { return res.json(); })
            .then(function (data) {
                if (data.success) {
                    showToast("Purchase submitted! Items will be delivered shortly.", "success");
                    clearCart();
                    closeModal();
                } else {
                    showToast(data.message || "Checkout failed.", "error");
                }
            })
            .catch(function () {
                showToast("Unable to process checkout. Try again.", "error");
            });
    }

    function toggleCart() {
        cartOpen = !cartOpen;
        els.cartPanel.classList.toggle("open", cartOpen);
    }

    window.addEventListener("message", function (event) {
        var data = event.data;
        if (!data || !data.action) return;
        switch (data.action) {
            case "openStore":
                packages = data.packages || [];
                categories = data.categories || [];
                playerInfo = data.playerInfo || null;
                updatePlayerDisplay();
                buildCategoryNav();
                renderProducts();
                els.loading.classList.add("hidden");
                els.app.style.display = "flex";
                setTimeout(function () {
                    els.app.classList.add("visible");
                }, 50);
                if (data.cart && Array.isArray(data.cart)) {
                    data.cart.forEach(function (item) {
                        cartItems[item.name] = item;
                    });
                    renderCartItems();
                }
                if (playerInfo && playerInfo.pendingCount > 0) {
                    updatePendingBanner(playerInfo.pendingCount);
                }
                break;
            case "cartUpdated":
                if (data.cart && Array.isArray(data.cart)) {
                    cartItems = {};
                    data.cart.forEach(function (item) {
                        cartItems[item.name] = item;
                    });
                }
                renderCartItems();
                break;
            case "pendingCount":
                updatePendingBanner(data.count);
                break;
            case "redeemResult":
                if (data.data && data.data.message) {
                    showToast(data.data.message, data.data.success ? "success" : "warning");
                }
                if (data.count !== undefined) {
                    updatePendingBanner(data.count);
                }
                break;
            case "purchaseQueued":
                showToast("Purchase " + data.data.packageName + " queued for delivery!", "success");
                break;
            case "playerInfo":
                playerInfo = data.playerInfo;
                updatePlayerDisplay();
                if (playerInfo.pendingCount > 0) {
                    updatePendingBanner(playerInfo.pendingCount);
                }
                break;
        }
    });

    function updatePlayerDisplay() {
        if (!playerInfo) return;
        els.playerName.textContent = playerInfo.name || "Player";
        var money = playerInfo.money ? playerInfo.money.bank || playerInfo.money.cash || 0 : 0;
        els.playerMoney.textContent =
            STORE_CONFIG.currency + Number(money).toLocaleString("en-US", { minimumFractionDigits: 2 });
    }

    function updatePendingBanner(count) {
        pendingCount = count;
        if (count > 0) {
            els.pendingBanner.classList.add("show");
            els.pendingCountBanner.textContent = count;
        } else {
            els.pendingBanner.classList.remove("show");
        }
    }

    function postNui(eventName, data) {
        fetch("https://cfx-nui-sinister_store/" + eventName, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify(data || {}),
        }).catch(function () {});
    }

    document.addEventListener("DOMContentLoaded", function () {
        cacheElements();
        els.searchInput.addEventListener("input", function () {
            renderProducts();
        });
        els.sortSelect.addEventListener("change", function () {
            renderProducts();
        });
        document.getElementById("btnCartToggle").addEventListener("click", toggleCart);
        document.getElementById("btnCartClose").addEventListener("click", toggleCart);
        document.getElementById("btnClose").addEventListener("click", function () {
            postNui("closeStore");
            els.app.classList.remove("visible");
            setTimeout(function () {
                els.app.style.display = "none";
            }, 300);
        });
        document.getElementById("btnClearCart").addEventListener("click", function () {
            clearCart();
            postNui("clearCart");
            showToast("Cart cleared.", "info");
        });
        document.getElementById("btnCheckout").addEventListener("click", openCheckoutModal);
        document.getElementById("modalClose").addEventListener("click", closeModal);
        document.getElementById("btnCancelPurchase").addEventListener("click", closeModal);
        document.getElementById("btnConfirmPurchase").addEventListener("click", confirmPurchase);
        document.getElementById("btnRedeem").addEventListener("click", function () {
            postNui("redeemPurchases");
        });
        document.getElementById("btnRedeemBanner").addEventListener("click", function () {
            postNui("redeemPurchases");
        });
        els.confirmModal.addEventListener("click", function (e) {
            if (e.target === els.confirmModal) closeModal();
        });
        postNui("checkPending");
        postNui("getPlayerInfo");
    });
})();
