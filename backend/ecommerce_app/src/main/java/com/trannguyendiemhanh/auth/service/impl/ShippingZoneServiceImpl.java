package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ShippingZone;
import com.trannguyendiemhanh.auth.repository.ShippingZoneRepository;
import com.trannguyendiemhanh.auth.service.ShippingZoneService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ShippingZoneServiceImpl extends JpaCrudServiceImpl<ShippingZone, UUID> implements ShippingZoneService {
    public ShippingZoneServiceImpl(ShippingZoneRepository repository) {
        super(repository);
    }
}
