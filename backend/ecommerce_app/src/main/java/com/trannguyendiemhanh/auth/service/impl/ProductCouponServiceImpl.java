package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.ProductCoupon;
import com.trannguyendiemhanh.auth.repository.ProductCouponRepository;
import com.trannguyendiemhanh.auth.service.ProductCouponService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class ProductCouponServiceImpl extends JpaCrudServiceImpl<ProductCoupon, UUID> implements ProductCouponService {
    public ProductCouponServiceImpl(ProductCouponRepository repository) {
        super(repository);
    }
}
