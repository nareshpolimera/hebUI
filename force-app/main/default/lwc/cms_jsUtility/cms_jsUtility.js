export function checkNull(value) {
    if (value === null || value === undefined) {
        return true;
    }
    
    if (Array.isArray(value) || typeof value === 'string') {
        return value.length === 0;
    }
    
    if (typeof value === 'object') {
        return Object.keys(value).length === 0;
    }
    
    return false;
}
export function isNull(value) {
    return value === null;
}

export function  isUndefined(value) {
    return value === undefined;
}
// validate email
export function validEmail(emailVal) {
    const emailRegex = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    if (!emailVal.match(emailRegex)) {
        console.log('log of email format')
        return true;
    }
    return false;
}

// validate phone
export function validatePhoneNumber(phoneNumber) {
    if(phoneNumber.match(/[0-9]{10}$/) && phoneNumber.length == 10){
        return false;
    }
    return true;
}