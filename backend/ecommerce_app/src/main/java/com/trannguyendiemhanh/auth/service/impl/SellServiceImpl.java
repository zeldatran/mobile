package com.trannguyendiemhanh.auth.service.impl;

import com.trannguyendiemhanh.auth.entity.Sell;
import com.trannguyendiemhanh.auth.repository.SellRepository;
import com.trannguyendiemhanh.auth.service.SellService;
import org.springframework.stereotype.Service;

import java.util.UUID;

@Service
public class SellServiceImpl extends JpaCrudServiceImpl<Sell, UUID> implements SellService {
    public SellServiceImpl(SellRepository repository) {
        super(repository);
    }
}
