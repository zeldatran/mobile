package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ShippingCountryZone;
import com.trannguyendiemhanh.auth.repository.ShippingCountryZoneRepository;
import com.trannguyendiemhanh.auth.service.ShippingCountryZoneService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ShippingCountryZoneServiceImpl extends JpaCrudServiceImpl<ShippingCountryZone, UUID> implements ShippingCountryZoneService {
    public ShippingCountryZoneServiceImpl(ShippingCountryZoneRepository repository) {
        super(repository);
    }
}
