\connect analytics

UPDATE customers
SET
    country = CASE
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 90 THEN 'United States'
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 149 THEN 'Germany'
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 195 THEN 'United Kingdom'
        WHEN get_byte(decode(md5('country-' || customer_id::text), 'hex'), 0) < 231 THEN 'Poland'
        ELSE 'Ukraine'
    END,
    acquisition_channel = CASE
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 77 THEN 'Organic'
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 141 THEN 'Google Ads'
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 192 THEN 'Meta Ads'
        WHEN get_byte(decode(md5('channel-' || customer_id::text), 'hex'), 0) < 230 THEN 'Referral'
        ELSE 'Email'
    END;
