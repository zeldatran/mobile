package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ShippingRate;
import com.trannguyendiemhanh.auth.repository.ShippingRateRepository;
import com.trannguyendiemhanh.auth.service.ShippingRateService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ShippingRateServiceImpl extends JpaCrudServiceImpl<ShippingRate, UUID> implements ShippingRateService {
    public ShippingRateServiceImpl(ShippingRateRepository repository) {
        super(repository);
    }
}
