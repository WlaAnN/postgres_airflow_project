import random
import math

def is_prime_miller_rabin(n, k=10):
    #Тест Миллера-Рабина на простоту
    if n < 2: return False
    if n in (2, 3): return True
    if n % 2 == 0: return False

    r, d = 0, n - 1
    while d % 2 == 0:
        r += 1
        d //= 2

    for _ in range(k):
        a = random.randrange(2, n - 1)
        x = pow(a, d, n)
        if x == 1 or x == n - 1:
            continue
        for _ in range(r - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                break
        else:
            return False
    return True

def generate_prime(bits):
    while True:
        n = random.getrandbits(bits)
        n |= (1 << bits - 1) | 1  #старший и младший биты = 1
        if is_prime_miller_rabin(n):
            return n

#Генерация ключей с проверками
def generate_rsa_keys(bits=512, e=65537):
    while True:
        p = generate_prime(bits // 2)
        q = generate_prime(bits // 2)
        if p == q: continue

        #Модификация: защита от близких простых
        if abs(p - q) < 2 ** (bits // 4):
            continue

        n = p * q
        phi = (p - 1) * (q - 1)
        if math.gcd(e, phi) != 1:
            continue

        d = pow(e, -1, phi)  # Python 3.8+
        return (n, e), (n, d), (p, q)

#упрощённый PKCS#1 v1.
def pkcs1_pad(message_bytes, key_len_bytes):
    max_msg_len = key_len_bytes - 11
    if len(message_bytes) > max_msg_len:
        raise ValueError("Сообщение слишком длинное для данного ключа")
    ps_len = key_len_bytes - 3 - len(message_bytes)
    ps = bytes([random.randint(1, 255) for _ in range(ps_len)])
    return b'\x00\x02' + ps + b'\x00' + message_bytes

def pkcs1_unpad(padded):
    if len(padded) < 11 or padded[0] != 0 or padded[1] != 2:
        raise ValueError("Неверный формат дополнения")
    separator = padded.index(0, 2)
    return padded[separator+1:]

#Шифрование, дешифрование
def encrypt(m_int, pub_key):
    n, e = pub_key
    if not (0 <= m_int < n):
        raise ValueError("Сообщение вне диапазона [0, N)")
    return pow(m_int, e, n)  #Быстрое возведение в степень (встроенное)

def decrypt(c_int, priv_key, p, q=None):
    n, d = priv_key
    #Модификация: CRT-дешифрование
    if p and q:
        return decrypt_crt(c_int, d, p, q)
    return pow(c_int, d, n)

#Модификация: CRT для ускорения
def decrypt_crt(c, d, p, q):
    dp = d % (p - 1)
    dq = d % (q - 1)
    qinv = pow(q, -1, p)

    m1 = pow(c, dp, p)
    m2 = pow(c, dq, q)

    h = (qinv * (m1 - m2)) % p
    m = m2 + h * q
    return m

if __name__ == "__main__":
    #Генерация ключей 512 бит
    pub, priv, (p, q) = generate_rsa_keys(bits=512, e=65537)
    print(f"N = {pub[0]}\ne = {pub[1]}")

    msg = b"Some_text"
    key_len_bytes = pub[0].bit_length() // 8  # Фиксированная длина блока
    
    #Шифрование
    padded = pkcs1_pad(msg, key_len_bytes)
    m_int = int.from_bytes(padded, byteorder='big')
    c = encrypt(m_int, pub)
    print(f"Шифротекст (первые 32 hex): {hex(c)[:34]}...")

    #Дешифрование с CRT
    m_dec = decrypt(c, priv, p, q)
    decrypted_bytes = m_dec.to_bytes(key_len_bytes, byteorder='big')
    
    original = pkcs1_unpad(decrypted_bytes)
    print(f"Расшифровано: {original.decode()}")
