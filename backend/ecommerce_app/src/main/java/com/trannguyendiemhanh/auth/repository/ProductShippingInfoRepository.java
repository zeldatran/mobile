package com.trannguyendiemhanh.auth.repository;

import com.trannguyendiemhanh.auth.entity.ProductShippingInfo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface ProductShippingInfoRepository extends JpaRepository<ProductShippingInfo, UUID> {}
