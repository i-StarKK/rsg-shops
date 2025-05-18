let currentItems = [];
let cart = [];
let selectedPaymentMethod = null;
const imageBasePath = 'nui://rsg-inventory/html/images/';
let currentShopName = null;


window.addEventListener('message', function(event) {
    if (event.data.type === 'open') {
        document.getElementById('shop-container').classList.remove('hidden');
        document.getElementById('shop-name').textContent = event.data.shopName;
        currentShopName = event.data.shopName;
        currentItems = event.data.items;
        updateItemsList(currentItems);
        updatePaymentMethods(event.data.paymentMethods);
        cart = [];
        updateCart();
    } else if (event.data.type === 'close') {
        document.getElementById('shop-container').classList.add('hidden');
        cart = [];
        updateCart();
    } else if (event.data.type === "updateCart") {
        cart = event.data.cart || [];
        updateCart();
    }
});

window.addEventListener('keydown', function(event) {
    const shopContainer = document.getElementById('shop-container');
    if (!shopContainer.classList.contains('hidden')) {
        if (event.key === ' ' || event.key === 'Escape') {
            console.log('Space or Escape key pressed, attempting to close shop');
            shopContainer.classList.add('hidden');
            if (typeof GetParentResourceName === 'function') {
                fetch(`https://${GetParentResourceName()}/close`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json; charset=UTF-8',
                    },
                    body: JSON.stringify({}),
                }).then(resp => resp.json()).then(resp => console.log('', resp)).catch(error => console.error('', error));
            }
        }
    }
});

function updateItemsList(items) {
    const itemsList = document.getElementById('items-list');
    itemsList.innerHTML = '';
    
    items.forEach((item, index) => {
        const itemElement = document.createElement('div');
        itemElement.className = 'item-card';
        itemElement.style.animationDelay = `${index * 0.05}s`;
        
        const imageSrc = typeof GetParentResourceName === 'function' 
            ? `${imageBasePath}${item.image}` 
            : `https://via.placeholder.com/120x120?text=${item.label}`;
        
        itemElement.innerHTML = `
            <img src="${imageSrc}" alt="${item.label}" onerror="this.src='https://via.placeholder.com/120x120?text=${item.label}'">
            <div class="item-info">
                <div class="item-name">${item.label}</div>
                <div class="item-price">$${typeof item.price === 'number' ? item.price.toFixed(2) : item.price}</div>
            </div>
            <button class="add-to-cart" data-item='${JSON.stringify(item)}'>Add to Cart</button>
        `;
        
        itemElement.querySelector('.add-to-cart').addEventListener('click', function() {
            const itemData = JSON.parse(this.dataset.item);
            addToCart(itemData);
        });
        
        itemsList.appendChild(itemElement);
    });
}

function updatePaymentMethods(methods) {
    const paymentOptions = document.getElementById('payment-options');
    paymentOptions.innerHTML = '';
    
    methods.forEach(method => {
        const option = document.createElement('div');
        option.className = 'payment-option';
        option.textContent = method.label;
        option.dataset.method = method.name;
        
        option.addEventListener('click', function() {
            document.querySelectorAll('.payment-option').forEach(opt => opt.classList.remove('selected'));
            this.classList.add('selected');
            selectedPaymentMethod = method.name;
        });
        
        paymentOptions.appendChild(option);
    });
}

function addToCart(item) {
    const existingItem = cart.find(cartItem => cartItem.name === item.name);
    
    if (existingItem) {
        existingItem.quantity++;
    } else {
        cart.push({
            ...item,
            quantity: 1
        });
    }
    
    updateCart();
}

function removeFromCart(itemName) {
    cart = cart.filter(item => item.name !== itemName);
    updateCart();
}

function updateCart() {
    const cartItems = document.getElementById('cart-items');
    const totalAmount = document.getElementById('total-amount');
    
    cartItems.innerHTML = '';
    let total = 0;
    
    cart.forEach((item, index) => {
        const itemTotal = item.price * item.quantity;
        total += itemTotal;
        
        const cartItemElement = document.createElement('div');
        cartItemElement.className = 'cart-item';
        cartItemElement.style.animationDelay = `${index * 0.05}s`;
        
        cartItemElement.innerHTML = `
            <div class="item-info">
                <div class="item-name">${item.label}</div>
                <div class="item-quantity">x${item.quantity}</div>
            </div>
            <div class="item-price">$${itemTotal.toFixed(2)}</div>
            <button class="remove-from-cart" data-item="${item.name}">Remove</button>
        `;
        
        cartItemElement.querySelector('.remove-from-cart').addEventListener('click', function() {
            removeFromCart(this.dataset.item);
        });
        
        cartItems.appendChild(cartItemElement);
    });
    
    totalAmount.textContent = `$${total.toFixed(2)}`;
}

document.getElementById('close-btn').addEventListener('click', function() {
    document.getElementById('shop-container').classList.add('hidden');
    
    if (typeof GetParentResourceName === 'function') {
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({})
        });
    }
});

document.getElementById('purchase-btn').addEventListener('click', function() {
    if (cart.length === 0) {
        return;
    }
    
    if (!selectedPaymentMethod) {
        const paymentSection = document.querySelector('.payment-section');
        paymentSection.style.animation = 'pulse 0.8s ease-in-out';
        setTimeout(() => {
            paymentSection.style.animation = '';
        }, 800);
        return;
    }

    let totalAmount = 0;
    for (const item of cart) {
        totalAmount += item.price * item.quantity;
    }
    if (typeof GetParentResourceName === 'function') {
        fetch(`https://${GetParentResourceName()}/purchase`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                items: cart,
                paymentMethod: selectedPaymentMethod,
                shopName: currentShopName
            })
        }).catch(error => {
            console.error('Purchase error:', error);
        });
    } else {
        console.log('Purchase completed:', {
            items: cart,
            paymentMethod: selectedPaymentMethod,
            shopName: currentShopName,
            total: totalAmount.toFixed(2)
        });
        const purchaseBtn = document.getElementById('purchase-btn');
        const originalText = purchaseBtn.textContent;
        purchaseBtn.textContent = 'Purchase Successful!';
        purchaseBtn.style.background = 'linear-gradient(to right, #059669, #10b981)';
        
        setTimeout(() => {
            purchaseBtn.textContent = originalText;
            purchaseBtn.style.background = '';
            cart = [];
            updateCart();
            document.querySelectorAll('.payment-option').forEach(opt => opt.classList.remove('selected'));
            selectedPaymentMethod = null;
        }, 2000);
    }
});

function addPulseEffect(element) {
    element.style.animation = 'pulse 0.8s ease-in-out';
    setTimeout(() => {
        element.style.animation = '';
    }, 800);
}