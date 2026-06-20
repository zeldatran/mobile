package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Coupon;
import com.trannguyendiemhanh.auth.repository.CouponRepository;
import com.trannguyendiemhanh.auth.service.CouponService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class CouponServiceImpl extends JpaCrudServiceImpl<Coupon, UUID> implements CouponService {
    public CouponServiceImpl(CouponRepository repository) {
        super(repository);
    }
}
