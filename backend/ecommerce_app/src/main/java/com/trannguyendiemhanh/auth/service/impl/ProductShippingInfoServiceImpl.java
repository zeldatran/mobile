package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductShippingInfo;
import com.trannguyendiemhanh.auth.repository.ProductShippingInfoRepository;
import com.trannguyendiemhanh.auth.service.ProductShippingInfoService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProductShippingInfoServiceImpl extends JpaCrudServiceImpl<ProductShippingInfo, UUID> implements ProductShippingInfoService {
    public ProductShippingInfoServiceImpl(ProductShippingInfoRepository repository) {
        super(repository);
    }
}
